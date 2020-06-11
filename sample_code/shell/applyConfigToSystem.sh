#!/bin/sh

defaultConfigPath="/am7x/case/data/"
userConfigPath="/mnt/vram/"

defaultConfig="${defaultConfigPath}sysconfig.default"
userConfig="${userConfigPath}projector_mgr/pjm_status_misc.cfg"
pjmConfigUser="${userConfigPath}projector_mgr/pjm_status_"
pjmConfigDefault="${defaultConfigPath}projector_mgr/pjm_status_"
# For display mode settings
defaultConfigExtension=".default"
userConfigExtension=".user"
backupConfigExtension=".old"
cfgConfigExtension=".cfg"
# List of the config files for all display modes
colorConfigList="bright standard cinema game sport"

# Indicate the config file for "initial" or "reset" but not including display mode related settings
configFile=""

# AM SysConfig Prefix
setting3D="SET_3D_"
settingAudio="SET_ADO_"
settingColor="SET_CLR_"
settingImage="SET_DSP_"
settingManagement="SET_MGT_"
settingLanguage="SYS_MGT_LANGUAGE"
settingNetwork="SET_NET_"
settingMedia="MDA_SET_"
settingADC="SYS_ADC_"

# Global variable
PJMode=""
PJLocation=""
#mute=0

displayModeConfig="SET_CLR_DSP_MODE"
tmpLastDisplayMode="LASTDISPMODE"

# 10 band settings for audio EQ
band01=""
band02=""
band03=""
band04=""
band05=""
band06=""
band07=""
band08=""
band09=""
band10=""

# Display Mode default value
displayModeValue=1

# 4 Corner setting is done or not
is4CornerSettingHandled=0

# List for the configs which do not reset.
# Each config seperate by comma without space, ex: notResetList="SET_DSP_PJ_LOCATION,SET_CLR_DM_BRIGHTNESS")
notResetList="SET_DSP_PJ_LOCATION"
forceReset=0

# List for the configs which will replace default config by its current value.
# Each config seperate by comma without space, ex: replaceDefaultValueList="SET_DSP_PJ_LOCATION,SET_CLR_DM_BRIGHTNESS")
replaceDefaultValueList=""

# ============== Handle config value and restore system status ==============
# Store config set(keys and values)
configSet=""

mapDisplayModeConfig()
{
    tmpParameter1=$1
    if [ "3d" == "$2" ]; then
        if [ "$tmpParameter1" = "initial" ]; then
            configFile="${userConfigPath}3d${userConfigExtension}"
        fi
        if [ "$tmpParameter1" = "reset" ]; then
            configFile="${defaultConfigPath}3d${defaultConfigExtension}"
        fi
        return
    fi

    IFS=$' '
    # Array-like usage for config list
    set -- ${colorConfigList}

    # Confirm and load SET_CLR_DSP_MODE first
    if [ "$tmpParameter1" = "reset" ]; then
        displayModeValue=`grep -w ${displayModeConfig} ${defaultConfig} | cut -d = -f 2`
        am_config.app -c ${displayModeConfig}=${displayModeValue}
    fi
    if [ "$tmpParameter1" = "initial" ]; then
        displayModeValue=`am_config.app -v ${displayModeConfig} | cut -d = -f 2`
    fi

    eval displayModeName=\$$((displayModeValue + 1))
    if [ "$tmpParameter1" = "reset" ]; then
        configFile="${defaultConfigPath}${displayModeName}${defaultConfigExtension}"
    fi
    if [ "$tmpParameter1" = "initial" ]; then
        configFile="${userConfigPath}${displayModeName}${userConfigExtension}"
    fi
    # echo $configFile
    IFS=$''
}

restoreAMConfig()
{
    setting=$2
    # Map display mode to config file name first
    if [ ${settingColor} = ${setting} ]; then
        mapDisplayModeConfig $1 $3
    else
	case $1 in
	reset)
	    case $2 in
	    $settingImage)
	    	configFile="${pjmConfigDefault}display$cfgConfigExtension"
	    ;;
	    $settingAudio)
	        configFile="${pjmConfigDefault}audio$cfgConfigExtension"
	    ;;
	    $settingManagement)
	        configFile="${pjmConfigDefault}system$cfgConfigExtension"
	    ;;
	    *)
		configFile=${defaultConfig}
	    ;;
	    esac
	;;
	initial)
	    case $2 in
            $settingImage)
	        configFile="${pjmConfigUser}display$cfgConfigExtension"
	    ;;
	    $settingAudio)
	        configFile="${pjmConfigUser}audio$cfgConfigExtension"
	    ;;
	    $settingManagement)
	        configFile="${pjmConfigUser}system$cfgConfigExtension"
	    ;;
	    *)
	        configFile=${userConfig}
	    ;;
	    esac
	;;
	*)
	;;
	esac
    fi

    # Reset configs
    if [ "$1" = "reset" ]; then
        IFS=$','
        # Replace default configs if it is reset mode and replaceDefaultValueList is not empty
        if [ -n "${replaceDefaultValueList}" ]; then
            for checkingConfig in $replaceDefaultValueList
            do
                replaceDefaultConfig=`am_config.app -v ${checkingConfig}`
                if [ -z "${replaceDefaultConfig}" ]; then
                    break;
                fi
                key=`echo ${replaceDefaultConfig} | cut -d = -f 1`
                sed -i "s/${key}=.*/${replaceDefaultConfig}/g" ${configFile}
            done
        fi

        configSet=`grep ^${setting} ${configFile}`
        if [ -n "${notResetList}" ] && [ ${forceReset} -eq 0 ]; then
            for notResetConfig in $notResetList
            do
                # Filter the configs which do not reset
                configSet=`echo $configSet | grep -v $notResetConfig`
            done
        fi
        configSet=`echo $configSet | awk "/${setting}/ {print}" ORS=','`
        IFS=$''
    fi

    # Initialize configs
    if [ "$1" = "initial" ]; then
        configSet=`cat ${configFile} | awk "/${setting}/ {print}" ORS=','`
    fi

    if [ ! -z "${configSet}" ]; then
        am_config.app -c $configSet
    else
        #echo "Can't get configs!"
        return
    fi
}

restoreSystemStatus()
{
    if [ -z "${configSet}" ]; then
        return
    fi

    IFS=$','
    for config in $configSet
    do
        key=`echo ${config} | cut -d = -f 1`
        value=`echo ${config//\"} | cut -d = -f 2 `
        #echo "$key = $value"

        case $1 in
            3d)
                runApply3DConfigs $key $value;;
            audio)
                runApplyAudioConfigs $key $value;;
            color)
                runApplyColorConfigs $key $value;;
            image)
                runApplyImageConfigs $key $value;;
            adc)
                runApplyImageConfigs $key $value;;
            management)
                runApplyManagementConfigs $key $value;;
            language)
                runApplyLanguageConfig $key $value;;
            network)
                runApplyNetworkConfigs $key $value;;
            *)
                #echo "Not support setting item, $2!"
                return;;
        esac
    done
    IFS=$''
}

# =============== Reset each setting item ===============
# ---------- Reset 3D ----------
runApply3DConfigs()
{
    key=$1
    value=$2

    case $key in
        SET_3D_ENABLE)
            case $value in
                0)
                    am_config.app -c HDMI_MANUAL_3D=0:v;;
                1)
                    am_config.app -c HDMI_MANUAL_3D=4:v;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
    # Reset HDMI 3D
    #echo "disp_source.app -h 3D=${value}"
    disp_source.app -h 3D=${value}
    # Reset VGA 3D
    #echo "disp_source.app -v 3D=${value}"
    disp_source.app -v 3D=${value}
}

apply3D()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $setting3D
    # Restore system status by each system app according to config value
    restoreSystemStatus 3d
}

# ---------- Reset Audio ----------
runApplyAudioConfigs()
{
    key=$1
    value=$2

    case $key in
        SET_ADO_VOL)
            if [ ${value} -ge 0 ] && [ ${value} -le 40 ]; then
                sys_ctrl.app -a volumeSetAbsValue=${value}
            fi
            if [ ${value} -eq 0 ]; then
                am_config.app -c SET_ADO_MUTE=1
            else
                am_config.app -d SET_ADO_MUTE
            fi
            #if [ ${mute} -eq 1 ]; then
                # Set mute again after set volumn if mute has been set
                #sys_ctrl.app -a volumeMute
            #fi
            return
            ;;
        SET_ADO_DTS)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_ADO_TREBLE)
            band08=${value}
            return;;
        SET_ADO_BASS)
            band01=${value}
            return;;
        SET_ADO_PWR_VOL)
            case ${value} in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
#        SET_ADO_MUTE)
#            case $value in
#                0)
#                    sys_ctrl.app -a volumeMute
#                    mute=1
#                    ;;
#                1)
#                    sys_ctrl.app -a volumeUnmute
#                    ;;
#                *)
                    #echo "There is no config value, $value!"
#                    return;;
#            esac
#            ;;
#        SET_ADO_EQ_band01)
#            band01=${value}
#            return;;
        SET_ADO_EQ_band02)
            band02=${value}
            return;;
        SET_ADO_EQ_band03)
            band03=${value}
            return;;
        SET_ADO_EQ_band04)
            band04=${value}
            return;;
        SET_ADO_EQ_band05)
            band05=${value}
            return;;
        SET_ADO_EQ_band06)
            band06=${value}
            return;;
        SET_ADO_EQ_band07)
            band07=${value}
            return;;
#        SET_ADO_EQ_band08)
#            band08=${value}
#            return;;
        SET_ADO_EQ_band09)
            band09=${value}
            return;;
        SET_ADO_EQ_band10)
            band10=${value}
            return;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyAudio()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingAudio
    # Restore system status by each system app according to config value
    restoreSystemStatus audio

    # Configure EQ settings
    echo "sys_ctrl.app -a ${band01} ${band02} ${band03} ${band04} ${band05} ${band06} ${band07} ${band08} ${band09} ${band10}"
    #sys_ctrl.app -a ${band01} ${band02} ${band03} ${band04} ${band05} ${band06} ${band07} ${band08} ${band09} ${band10}
}

# ---------- Reset Color ----------
runApplyColorConfigs()
{
    key=$1
    value=$2

    case $key in
        SET_CLR_DM_BRIGHTNESS)
            #echo "scaler.app -c brightness=${value}"
            scaler.app -c brightness=${value}
            ;;
        SET_CLR_DM_CONTRAST)
            #echo "scaler.app -c contrast=${value}"
            scaler.app -c contrast=${value}
            ;;
        SET_CLR_DM_SATURATION)
            #echo "scaler.app -c saturation=${value}"
            scaler.app -c saturation=${value}
            ;;
        SET_CLR_DM_SHARPNESS)
            #echo "scaler.app -m sharpValue=${value}"
            scaler.app -m sharpValue=${value}
            ;;
        SET_CLR_DM_TEMP)
            case $value in
                0)
                    value="4500";;
                1)
                    value="6600";;
                2)
                    value="20000";;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "scaler.app -c colorTemperature=${value}"
            scaler.app -c colorTemperature=${value}
            ;;
        SET_CLR_DM_GAMMA)
            #echo "scaler.app -g gammaValue=${value}"
            scaler.app -g gammaValue=${value}
            ;;
        SET_CLR_DM_HUE)
            #echo "scaler.app -c hue=${value}"
            scaler.app -c hue=${value}
            ;;
        SET_CLR_DM_WALL_CLR)
            case $value in
                0)
                    value="white";;
                1)
                    value="lightYellow";;
                2)
                    value="lightBlue";;
                3)
                    value="pink";;
                4)
                    value="darkGreen";;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "scaler.app -c wallColor=${value}"
            scaler.app -c wallColor=${value}
            ;;
        SET_CLR_DM_RGAIN)
            #echo "scaler.app -g rGain=${value}"
            scaler.app -g rGain=${value}
            ;;
        SET_CLR_DM_GGAIN)
            #echo "scaler.app -g gGain=${value}"
            scaler.app -g gGain=${value}
            ;;
        SET_CLR_DM_BGAIN)
            #echo "scaler.app -g bGain=${value}"
            scaler.app -g bGain=${value}
            ;;
        SET_CLR_DM_ROFFSET)
            #echo "scaler.app -g rOffset=${value}"
            scaler.app -g rOffset=${value}
            ;;
        SET_CLR_DM_GOFFSET)
            #echo "scaler.app -g gOffset=${value}"
            scaler.app -g gOffset=${value}
            ;;
        SET_CLR_DM_BOFFSET)
            #echo "scaler.app -g bOffset=${value}"
            scaler.app -g bOffset=${value}
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

restoreColorDefaultConfigFile()
{
    if [ "3d" == "$1" ]; then
        colorDefaultConfig="${defaultConfigPath}3d${defaultConfigExtension}"
        colorUserConfig="${userConfigPath}3d${userConfigExtension}"
        colorBackupConfig="${userConfigPath}3d${backupConfigExtension}"
        cp ${colorDefaultConfig} ${colorUserConfig}; sync
        cp ${colorUserConfig} ${colorBackupConfig}; sync
        return
    fi

    IFS=$' '
    for config in ${colorConfigList}
    do
        colorDefaultConfig="${defaultConfigPath}${config}${defaultConfigExtension}"
        colorUserConfig="${userConfigPath}${config}${userConfigExtension}"
        colorBackupConfig="${userConfigPath}${config}${backupConfigExtension}"
        cp ${colorDefaultConfig} ${colorUserConfig}; sync
        cp ${colorUserConfig} ${colorBackupConfig}; sync
    done
    IFS=$''
}

applyColor()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingColor $2
    # Restore system status by each system app according to config value
    restoreSystemStatus color
    # Restore Color related default config files to user config files and then backup user config files
    if [ "$1" = "reset" ]; then
        restoreColorDefaultConfigFile $2
    fi
}

# ---------- Reset Image ----------
handle4CornerSetting()
{
    if [ "${userConfig}" = "${configFile}" ]; then
        #echo "scaler.app -k fourCorStep=restore"
        scaler.app -k fourCorStep=restore
    fi
    if [ "${defaultConfig}" = "${configFile}" ]; then
        #echo "scaler.app -k fourCorStep=resetAll"
        scaler.app -k fourCorStep=resetAll
    fi
    is4CornerSettingHandled=1
}

runApplyImageConfigs()
{
    key=$1
    value=$2
	hardware=$(grep VERSION_HARDWARE /etc/version.conf | cut -d = -d ' ' -f 3)
	#echo hardware = $hardware

    case $key in
        SET_DSP_PJ_MODE)
            if [ -z $PJLocation ]; then
                PJMode=${value}
                #echo "PJMode = ${value}"
                return
            fi

			if [ $hardware == "AM8280.SZ" ]; then
				return
			else
				case $value in
					0)
						case $PJLocation in
							0)
								value="degree0";;
							1)
								value="degree0";;
							2)
								value="degree180";;
							*)
								#echo "There is no PJLocation config value, $PJLocation!"
								return;;
						esac
						;;
					1)
						case $PJLocation in
							0)
								value="horFlip";;
							1)
								value="horFlip";;
							2)
								value="verFlip";;
							*)
								#echo "There is no PJLocation config value, $PJLocation!"
								return;;
						esac
						;;
					*)
						#echo "There is no config value, $value!"
						return;;
				esac
			fi
            #echo "scaler.app -k rotateType=${value}"
            scaler.app -k rotateType=${value}
            ;;
        SET_DSP_PJ_LOCATION)
			if [ -z $PJMode ]; then
				PJLocation=${value}
				#echo "PJLocation = ${value}"
				return
			fi
			if [ $hardware == "AM8280.SZ" ]; then
				return
			else

				case $value in
					0)
						case $PJMode in
							0)
								value="degree0";;
							1)
								value="horFlip";;
							*)
								#echo "There is no PJMode config value, $PJMode!"
								return;;
						esac
						;;
					1)
						case $PJMode in
							0)
								value="degree0";;
							1)
								value="horFlip";;
							*)
								#echo "There is no PJMode config value, $PJMode!"
								return;;
						esac
						;;
					2)
						case $PJMode in
							0)
								value="degree180";;
							1)
								value="verFlip";;
							*)
								#echo "There is no PJMode config value, $PJMode!"
								return;;
						esac
						;;
					*)
						#echo "There is no config value, $value!"
						return;;
				esac
			fi
            #echo "scaler.app -k rotateType=${value}"
            scaler.app -k rotateType=${value}
            ;;
		SET_DSP_PJ_LOCATION_MODE)
			if [ $hardware == "AM8280.SZ" ]; then
				case $value in
					0)
						value="degree0";;
					1)
						value="degree180";;
					2)
						value="horFlip";;
					3)
						value="verFlip";;
					*)
						return;;
				esac
			fi
            #echo "scaler.app -k rotateType=${value}"
            scaler.app -k rotateType=${value}
            ;;
        SET_DSP_RATIO)
            case $value in
                0)
                    method="fit"
                    ratio="origin"
                    ;;
                1)
                    method="fullScreen"
                    ratio="origin"
                    ;;
                2)
                    method="fit"
                    ratio="4:3"
                    ;;
                3)
                    method="fit"
                    ratio="16:9"
                    ;;
                4)
                    method="letterBox"
                    ratio="origin"
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "scaler.app -k aspectMethod=${method}"
            scaler.app -k aspectMethod=${method}
            #echo "scaler.app -k aspectRatio=${ratio}"
            scaler.app -k aspectRatio=${ratio}
            ;;
        SET_DSP_AUTO_VKS)
            case $value in
                0)
                    vkeystone.app -q
                    ;;
                1)
                    vkeystone.app -i&
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_DSP_VKS)
        	# comment out resotre, and restore with h/v keystone cmd [2017 Q2 Ray]
            if [ ${is4CornerSettingHandled} -eq 0 ]; then
                handle4CornerSetting
            fi
            #echo "scaler.app -k vAngle=${value}"
            scaler.app -k vAngle=${value}
            ;;
        SET_DSP_HKS)
            if [ ${is4CornerSettingHandled} -eq 0 ]; then
                handle4CornerSetting
            fi
            #echo "scaler.app -k hAngle=${value}"
            scaler.app -k hAngle=${value}
            ;;
        SET_DSP_HPS)
            #echo "disp_source.app -v pos_offset=${value}"
            #disp_source.app -v pos_offset=${value}
            ;;
        SET_DSP_VPS)
            #echo "disp_source.app -v v_pos_offset=${value}"
            #disp_source.app -v v_pos_offset=${value}
            ;;
        SET_DSP_FREQ)
            #echo "disp_source.app -v clk_offset=${value}"
            #disp_source.app -v clk_offset=${value}
            ;;
        SET_DSP_TRACKING)
            #echo "disp_source.app -v phase=${value}"
            #disp_source.app -v phase=${value}
            ;;
        SET_DSP_HDMI_CLR_RANGE)
            case $value in
                0)
                    value=0;;
                1)
                    value=1;;
                2)
                    value=2;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "disp_source.app -h color_range=${value}"
            disp_source.app -h color_range=${value}
            ;;
        SET_DSP_SCAN_INFO)
            case $value in
                0)
                    value=0;;
                1)
                    value=1;;
                2)
                    value=2;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "disp_source.app -h overscan=${value}"
            disp_source.app -h overscan=${value}
            ;;
        SET_DSP_ZOOM)
            case $value in
                0)
                    value=1;;
                1)
                    value=1.04;;
                2)
                    value=1.08;;
                3)
                    value=1.12;;
                4)
                    value=1.16;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "scaler.app -k zoomValue=${value},zoomXStep=0,zoomYStep=0"
            scaler.app -k zoomValue=${value},zoomXStep=0,zoomYStep=0
            ;;
        SYS_ADC_R_GAIN)
            #echo "disp_source.app -v adc_r_gain=${value}"
            disp_source.app -v adc_r_gain=${value}
            ;;
        SYS_ADC_G_GAIN)
            #echo "disp_source.app -v adc_g_gain=${value}"
            disp_source.app -v adc_g_gain=${value}
            ;;
        SYS_ADC_B_GAIN)
            #echo "disp_source.app -v adc_b_gain=${value}"
            disp_source.app -v adc_b_gain=${value}
            ;;
        SYS_ADC_R_OFFSET)
            #echo "disp_source.app -v adc_r_offset=${value}"
            disp_source.app -v adc_r_offset=${value}
            ;;
        SYS_ADC_G_OFFSET)
            #echo "disp_source.app -v adc_g_offset=${value}"
            disp_source.app -v adc_g_offset=${value}
            ;;
        SYS_ADC_B_OFFSET)
            #echo "disp_source.app -v adc_b_offset=${value}"
            disp_source.app -v adc_b_offset=${value}
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyImage()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingImage
    # Restore system status by each system app according to config value
    restoreSystemStatus image

    applyADC $1
}

# ---------- Reset VGA ADC ----------
runApplyADCConfig()
{
    key=$1
    value=$2

    case $key in
        SYS_ADC_R_GAIN)
            #echo "disp_source.app -v adc_r_gain=${value}"
            disp_source.app -v adc_r_gain=${value}
            ;;
        SYS_ADC_G_GAIN)
            #echo "disp_source.app -v adc_g_gain=${value}"
            disp_source.app -v adc_g_gain=${value}
            ;;
        SYS_ADC_B_GAIN)
            #echo "disp_source.app -v adc_b_gain=${value}"
            disp_source.app -v adc_b_gain=${value}
            ;;
        SYS_ADC_R_OFFSET)
            #echo "disp_source.app -v adc_r_offset=${value}"
            disp_source.app -v adc_r_offset=${value}
            ;;
        SYS_ADC_G_OFFSET)
            #echo "disp_source.app -v adc_g_offset=${value}"
            disp_source.app -v adc_g_offset=${value}
            ;;
        SYS_ADC_B_OFFSET)
            #echo "disp_source.app -v adc_b_offset=${value}"
            disp_source.app -v adc_b_offset=${value}
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyADC()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingADC
    # Restore system status by each system app according to config value
    restoreSystemStatus adc
}

# ---------- Reset Management ----------
runApplyManagementConfigs()
{
    key=$1
    value=$2

	model=$(grep MODEL /etc/version.conf | cut -d = -d ' ' -f 3)
	#echo model = $model
	if [ $model == "am_8280_sz_j1" ] || [ $model == "am_8280_sz_j2" ]  ; then
		eco=$(am_config.app -a | grep SET_MGT_ECO | cut -d "=" -f2)
		if [ $eco == "0" ];then
			PWM_LOW="200:200:200"
		else
			PWM_HIGH="490:490:490"
		fi
	fi

	if [ $model == "am_8280_sz_c202i" ] || [ $model == "am_8280_sz_aopen" ] ; then
		eco=$(am_config.app -a | grep SET_MGT_ECO | cut -d "=" -f2)
		if [ $eco == "0" ];then
			PWM_LOW="100:100:100"
		else
			PWM_HIGH="574:574:574"
		fi
	fi

    case $key in
        SET_MGT_LANG_INDEX)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_MGT_AUTO_SHUTDOWN)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_MGT_ECO)
			case $value in
				0)
					value=$PWM_LOW;
					;;
				1)
					value=$PWM_HIGH
					;;
				*)
					#echo "There is no config value, $value!"
					return;
					;;
			esac
			test_dlp.app -w wpwm=${value}
			;;
        SET_MGT_USB5V)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_MGT_HI_ALTITUDE)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        SET_MGT_AC_ON)
            case $value in
                0)
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyManagement()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingManagement
    # Restore system status by each system app according to config value
    restoreSystemStatus management

    applyLanguage $1
}

# ---------- Reset Language ----------
runApplyLanguageConfig()
{
    key=$1
    value=$2

    case $key in
        SYS_MGT_LANGUAGE)
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyLanguage()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingLanguage
    # Restore system status by each system app according to config value
    restoreSystemStatus language
}

# ---------- Reset Network ----------
runApplyNetworkConfigs()
{
    key=$1
    value=$2

    am_config.app -c SET_NET_WIFI_ENABLE=1
    am_config.app -c POLICY_DONGLE_EVT="allow"

    case $key in
        SET_NET_WIFI_ENABLE)
            case $value in
                0)
                    value="off";;
                1)
                    value="on"
                    sys_eventd.app -w ${value} &
                    ;;
                *)
                    #echo "There is no config value, $value!"
                    return;;
            esac
            #echo "net_setting.app -w ${value}"
            #net_setting.app -w ${value} &
            ;;
        *)
            #echo "There is no config key, $key!"
            return;;
    esac
}

applyNetwork()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingNetwork
    # Restore system status by each system app according to config value
    restoreSystemStatus network
}

applyNetwork_resetDefApStaLan()
{
    #clean up network setting for ap, sta, lan iface
    # net_master.app will set to default setting when initial time
    rm /mnt/user1/clientap/linked_apList
    rm /mnt/user1/softap/rtl_hostapd.conf
    rm /mnt/user1/lan/lan_info
}

# ---------- Reset Media(Audio/Photo/Video) ----------
applyMedia()
{
    # Restore config value by am_config.app
    restoreAMConfig $1 $settingMedia
}

# ======================= reset ===========================
reset()
{
    case $2 in
        #3d)
            #apply3D $1;;
        audio)
            applyAudio $1;;
        3dcolor)
            applyColor $1 3d;;
        color)
            applyColor $1;;
        image)
            applyImage $1;;
        management)
            applyManagement $1;;
        network)
            applyNetwork $1;;
        media)
            applyMedia $1;;
        all)
            #apply3D $1
            applyAudio $1
            # "Reset all" needs to check it is 2D or 3D mode so comment this out.
            #applyColor $1
            applyImage $1
            applyManagement $1
            applyNetwork $1
            applyMedia $1
            applyNetwork_resetDefApStaLan
            ;;
        projector)
            forceReset=1
            applyAudio $1
            #applyColor $1 3d
            #applyColor $1
            applyImage $1
            applyManagement $1
            applyNetwork $1
            applyMedia $1
            ;;
        *)
            #echo "Not support setting item, $2!"
            return;;
    esac
}

# ====================== initial ==========================
initial()
{
    case $2 in
        3dcolor)
            applyColor $1 3d;;
        color)
            applyColor $1;;
        image)
            applyImage $1;;
        *)
            #apply3D $1
            applyAudio $1
            applyManagement $1
            # Network application will do the initialization
            #applyNetwork $1
            ;;
    esac
}

# main
if [ ! -z $1 ]; then
    case $1 in
        reset)
            reset $1 $2;;
        initial)
            initial $1 $2;;
        *)
            #echo "Not support action, $1!"
            return;;
    esac
else
    #echo "Not specifying the action(reset/initial)!"
    return
fi

TARGET_TYPE = ar

ROOT_DIR  = ./../../..
IMAGE     = ubox
TARGET    = $(SDK_LIB_DIR)/$(IMAGE_AR)

INCS = $(SDK_DIR)/include \
	$(SDK_DIR)/linux/include \
	$(SDK_DIR)/include/am_app \
	$(SDK_DIR)/inc \
	$(CASE_DIR)/include \

CFLAGS_EXTRA=-Dubox_EXPORTS -DBUILD_LUA=off -fPIC --std=gnu99
#  -fPIC -Os -Wall -Werror -g3 -Wmissing-declarations  
LIBS= $(SDK_LIB_DIR)/libjson.a

include $(ROOT_DIR)/scripts/common.mak

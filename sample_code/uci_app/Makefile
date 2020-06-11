# 2016/12/06 Week #49
# zivchen
#
#
TARGET_TYPE = app

ROOT_DIR  = ./../../..
IMAGE     = uci 
TARGET    = $(IMG_DIR)/$(IMAGE_APP)

INCS = $(SDK_DIR)/include \
	$(SDK_DIR)/library/libuci \
	$(SDK_INCLUDE)

CFLAGS_EXTRA=-Duci_EXPORTS --std=gnu99 -DBUILD_LUA=off

LIBS = $(SDK_LIB_DIR)/libuci.a 

include $(ROOT_DIR)/scripts/common.mak


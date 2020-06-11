TARGET_TYPE = ar

ROOT_DIR  = ./../../..
IMAGE     = uci 
TARGET    = $(SDK_LIB_DIR)/$(IMAGE_AR)

INCS = $(SDK_DIR)/library/

CFLAGS_EXTRA=-Duci_EXPORTS --std=gnu99 -fPIC -DBUILD_LUA=off 
#LIBS = -L$(SDK_DIR)/lib -lubox

LIBS = $(SDK_LIB_DIR)/libubox.a
include $(ROOT_DIR)/scripts/common.mak

#
# Copyright (C) 2013 Inteno
# Copyright (C) 2016 Martin K. Schröder
# Copyright (C) 2017 LibreMesh.org
# This software is free software distributed under 
# GNU General Public License version 3 or any later version. 
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=lime-webui-ng
PKG_VERSION:=1
PKG_RELEASE:=1
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/lime-webui-ng
  CATEGORY:=LiMe
  DEPENDS:= +orange-rpcd +lighttpd-ws +lighttpd-ws-mod-websocket +lighttpd-ws-mod-proxy +lighttpd-ws-mod-cgi
  TITLE:= Advanced web user interface for LibreMesh
endef

define Package/lime-webui-ng/description
	Set of packages required for lime-webui-ng. A JavaScript web interface using websockets.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	echo "Nothing to compile!"
endef 

define Package/luci-webui-ng/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,lime-webui-ng))

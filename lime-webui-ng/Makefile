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

define Package/$(PKG_NAME)/Default
  SECTION:=net
  CATEGORY:=LiMe
  MAINTAINER:=p4u <p4u@dabax.net>
  URL:=http://libremesh.org
endef

define Package/$(PKG_NAME)
  $(call Package/$(PKG_NAME)/Default)
  TITLE:= Advanced web user interface for LibreMesh
  DEPENDS:=+orange-rpcd +lighttpd-ws +lighttpd-ws-mod-websocket \
					+lighttpd-ws-mod-proxy
endef

define Package/$(PKG_NAME)-luci
  $(call Package/$(PKG_NAME)/Default)
  TITLE:= Add LuCi in addition to $(PKG_NAME)
  DEPENDS:=+$(PKG_NAME) +luci-mod-admin-full +lime-system \
					+PACKAGE_lime-proto-bmx6:luci-app-bmx6 \
					+PACKAGE_lime-proto-batadv:luci-app-batman-adv \
					+luci-mod-status +uhttpd +libiwinfo-lua \
					+luci-theme-bootstrap +luci-i18n-base-en \
					+lighttpd-ws-mod-rewrite +lighttpd-ws-mod-cgi
endef

define Package/$(PKG_NAME)/description
	Set of packages required for lime-webui-ng. A JavaScript web interface using websockets.
endef

define Package/$(PKG_NAME)-luci/description
  Add standard LuCi web interface in addition to $(PKG_NAME)
endef


define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile
	echo "Nothing to compile!"
endef 

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)-luci/install
	$(CP) ./files-luci/* $(1)/
endef


$(eval $(call BuildPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)-luci))

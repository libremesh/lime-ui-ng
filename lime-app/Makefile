# 
# Copyright (C) 2017 Marcos Gutierrez
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lime-app
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE_URL:=https://github.com/libremesh/lime-app/branches/gh-pages
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=HEAD
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	CATEGORY:=LiMe
	TITLE:=LimeApp
	MAINTAINER:=Marcos Gutierrez <gmarcos87@gmail.com>
	URL:=http://github.com/libremesh/lime-app
endef

define Package/$(PKG_NAME)/description
	Light webApp for LibreMesh
endef

define Build/Compile
	mkdir -p $(PKG_BUILD_DIR)/app
	mv $(PKG_BUILD_DIR)/*.* $(PKG_BUILD_DIR)/app
	mv $(PKG_BUILD_DIR)/assets $(PKG_BUILD_DIR)/app
	mv $(PKG_BUILD_DIR)/appcache $(PKG_BUILD_DIR)/app

endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/www/app/
	$(CP) $(PKG_BUILD_DIR)/app/* $(1)/www/app/	
endef

$(eval $(call BuildPackage,lime-app))

#
# Copyright (C) 2006-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=lighttpd-ws
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mkschreder/juci-lighttpd.git
PKG_SOURCE_VERSION:=23644e8f150baac0aa5199a6820234d8e7898231
PKG_VERSION:=1.4.33
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_MAINTAINER:=Pau Escrich <p4u@dabax.net>
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

PKG_FIXUP:=autoreconf
PKG_INSTALL:=1

include $(INCLUDE_DIR)/package.mk

define Package/lighttpd-ws/Default
  SUBMENU:=Web Servers/Proxies
  SECTION:=net
  CATEGORY:=Network
  URL:=http://www.lighttpd.net/
  MAINTAINER:=W. Michael Petullo <mike@flyn.org>
endef

define Package/lighttpd-ws
  $(call Package/lighttpd-ws/Default)
  MENU:=1
  DEPENDS:=+LIGHTTPD_WS_SSL:libopenssl +libpcre +libpthread
  TITLE:=Lighttpd with websocket support
endef

define Package/lighttpd-ws/config
config LIGHTTPD_WS_SSL
	bool "SSL support"
	depends on PACKAGE_lighttpd-ws
	default n
	help
	  Implements SSL support in lighttpd-ws (using libopenssl). This
	  option is required if you enable the SSL engine in your
	  lighttpd confguration file.
endef
 
define Package/lighttpd-ws-mod-websocket
  $(call Package/lighttpd-ws/Default)
  DEPENDS:=+lighttpd-ws
  TITLE:=Websockets module for lighttpd-ws
endef

define Package/lighttpd-ws-mod-cgi
  $(call Package/lighttpd-ws/Default)
  DEPENDS:=+lighttpd-ws
  TITLE:=CGI module for lighttpd-ws
endef

define Package/lighttpd-ws-mod-proxy
  $(call Package/lighttpd-ws/Default)
  DEPENDS:=+lighttpd-ws
  TITLE:=Proxy module for lighttpd-ws
endef

define Package/lighttpd-ws-mod-redirect
  $(call Package/lighttpd-ws/Default)
  DEPENDS:=+lighttpd-ws +libpcre
  TITLE:=URL redirection module for lighttpd-ws
endef

define Package/lighttpd-ws-mod-rewrite
  $(call Package/lighttpd-ws/Default)
  DEPENDS:=+lighttpd-ws +libpcre
  TITLE:=URL rewriting module for lighttpd-ws
endef

CONFIGURE_ARGS+= \
	--libdir=/usr/lib/lighttpd \
	--sysconfdir=/etc \
	--enable-shared \
	--enable-static \
	--disable-rpath \
	--without-attr \
	--without-bzip2 \
	--without-fam \
	--without-gdbm \
	--without-ldap \
	--without-lua \
	--without-memcache \
	--without-mysql \
	--with-pcre \
	--without-valgrind \
	 $(call autoconf_bool,CONFIG_IPV6,ipv6)

CONFIGURE_VARS+= \
	PCRE_LIB="-lpcre" \

ifneq ($(strip $(CONFIG_LIGHTTPD_WS_SSL)),)
  CONFIGURE_ARGS+= \
	--with-openssl="$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= \
	--without-openssl
endif
 
ifneq ($(SDK)$(CONFIG_PACKAGE_lighttpd-ws-mod-websocket),)
  CONFIGURE_ARGS+= \
	--with-websocket=ALL \
        --with-libicu=no
endif

define Build/Configure
$(call Build/Configure/Default)
	# XXX: override pcre (mis)detection by ./configure when cross-compiling
	echo "#define HAVE_LIBPCRE 1" >>$(PKG_BUILD_DIR)/config.h
	echo "#define HAVE_PCRE_H 1" >>$(PKG_BUILD_DIR)/config.h
endef

define Package/lighttpd-ws/conffiles
/etc/lighttpd/lighttpd.conf
endef

define Package/lighttpd-ws/install
	$(INSTALL_DIR) $(1)/etc
	$(CP) ./files/etc/* $(1)/etc/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/lighttpd.init $(1)/etc/init.d/lighttpd
	$(INSTALL_DIR) $(1)/usr/lib/lighttpd
	for m in dirlisting indexfile staticfile; do \
		$(CP) $(PKG_INSTALL_DIR)/usr/lib/lighttpd/mod_$$$${m}.so $(1)/usr/lib/lighttpd/ ; \
	done
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/usr/sbin/lighttpd $(1)/usr/sbin/
endef

define BuildPlugin
  define Package/$(1)/install
	[ -z "$(2)" ] || $(INSTALL_DIR) $$(1)/usr/lib/lighttpd
	for m in $(2); do \
		$(CP) $(PKG_INSTALL_DIR)/usr/lib/lighttpd/mod_$$$$$$$${m}.so $$(1)/usr/lib/lighttpd/ ; \
	done
  endef

  $$(eval $$(call BuildPackage,$(1)))
endef

$(eval $(call BuildPackage,lighttpd-ws))
$(eval $(call BuildPlugin,lighttpd-ws-mod-cgi,cgi))
$(eval $(call BuildPlugin,lighttpd-ws-mod-proxy,proxy))
$(eval $(call BuildPlugin,lighttpd-ws-mod-websocket,websocket))
$(eval $(call BuildPlugin,lighttpd-ws-mod-rewrite,rewrite))
$(eval $(call BuildPlugin,lighttpd-ws-mod-redirect,redirect))


include $(TOPDIR)/rules.mk

PKG_NAME:=vohive-core
PKG_VERSION:=$(if $(VOHIVE_VERSION),$(VOHIVE_VERSION),v1.4.3)
PKG_RELEASE:=1
PKG_LICENSE:=Proprietary
PKG_MAINTAINER:=VoHive

include $(INCLUDE_DIR)/package.mk

define Package/vohive-core
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=VoHive core binary
  DEPENDS:=
endef

define Package/vohive-core/description
  Preinstalled VoHive core binary for luci-app-vohive.
endef

define Build/Compile
endef

define Package/vohive-core/install
	$(INSTALL_DIR) $(1)/etc/vohive/bin
	$(INSTALL_BIN) ./files/vohive $(1)/etc/vohive/bin/vohive
	echo "$(PKG_VERSION)" > $(1)/etc/vohive/bin/version
endef

define Package/vohive-core/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	if [ -x /etc/init.d/vohive ] && /etc/init.d/vohive running >/dev/null 2>&1; then
		/etc/init.d/vohive restart || true
	fi
}
exit 0
endef

$(eval $(call BuildPackage,vohive-core))

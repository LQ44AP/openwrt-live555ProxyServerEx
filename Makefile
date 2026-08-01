include $(TOPDIR)/rules.mk

PKG_NAME:=live555ProxyServerEx
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

# Live555 源码地址
LIVE555_SOURCE:=live555-latest.tar.gz
LIVE555_SITE:=https://download.live555.com/
PKG_HASH:=skip

# Live555ProxyServerEx 源码地址
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/andreymal/live555ProxyServerEx.git
PKG_SOURCE_VERSION:=master
PKG_SOURCE:=$(PKG_NAME)-$(PKG_SOURCE_VERSION).tar.gz
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/live555ProxyServerEx
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Video
  TITLE:=Live555 RTSP Proxy Server Extended
  DEPENDS:=+libstdcpp +libpthread
endef

define Package/live555ProxyServerEx/description
  Extended version of LIVE555 RTSP Proxy Server with config file and procd service support.
endef

# ---------------------------------------------------------------------
# 重点 1：标记配置文件，避免用户升级/重新安装 IPK 时覆盖用户自定义配置
# ---------------------------------------------------------------------
define Package/live555ProxyServerEx/conffiles
/etc/live555proxy.conf
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	$(SCRIPT_DIR)/download.pl "$(DL_DIR)" "$(LIVE555_SOURCE)" "x" "$(LIVE555_SITE)"
	mkdir -p $(PKG_BUILD_DIR)/live
	$(TAR) -zxvf $(DL_DIR)/$(LIVE555_SOURCE) -C $(PKG_BUILD_DIR)/
endef

define Build/Compile
	# 编译 LIVE555 静态库
	cd $(PKG_BUILD_DIR)/live && \
		./genMakefiles linux && \
		$(MAKE) \
			CC="$(TARGET_CC)" \
			CXX="$(TARGET_CXX)" \
			CFLAGS="$(TARGET_CFLAGS)" \
			CXXFLAGS="$(TARGET_CXXFLAGS)"

	# 编译 Live555ProxyServerEx
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		INCLUDES="-I$(PKG_BUILD_DIR)/live/liveMedia/include \
                  -I$(PKG_BUILD_DIR)/live/UsageEnvironment/include \
                  -I$(PKG_BUILD_DIR)/live/BasicUsageEnvironment/include \
                  -I$(PKG_BUILD_DIR)/live/groupsock/include" \
		LIBS="$(PKG_BUILD_DIR)/live/liveMedia/libliveMedia.a \
              $(PKG_BUILD_DIR)/live/groupsock/libgroupsock.a \
              $(PKG_BUILD_DIR)/live/BasicUsageEnvironment/libBasicUsageEnvironment.a \
              $(PKG_BUILD_DIR)/live/UsageEnvironment/libUsageEnvironment.a \
              -lpthread"
endef

# ---------------------------------------------------------------------
# 重点 2：将可执行程序、配置文件和 procd 启动脚本一并打包进 IPK
# ---------------------------------------------------------------------
define Package/live555ProxyServerEx/install
	# 1. 安装主程序到 /usr/bin/
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/live555ProxyServerEx $(1)/usr/bin/

	# 2. 安装默认配置文件到 /etc/
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_CONF) ./files/live555proxy.conf $(1)/etc/live555proxy.conf

	# 3. 安装 procd 启动脚本到 /etc/init.d/ 并赋予执行权限
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/live555proxy.init $(1)/etc/init.d/live555proxy
endef

$(eval $(call BuildPackage,live555ProxyServerEx))

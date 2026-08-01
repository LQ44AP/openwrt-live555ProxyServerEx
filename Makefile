include $(TOPDIR)/rules.mk

PKG_NAME:=live555ProxyServerEx
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

# ----------------------------------------------------
# 1. 下载 Live555 最新源码包
# ----------------------------------------------------
LIVE555_SOURCE:=live555-latest.tar.gz
LIVE555_SITE:=https://download.live555.com/
PKG_HASH:=skip  # 忽略 MD5/SHA256 校验（因为 -latest 文件的哈希值会随官方更新而改变）

# ----------------------------------------------------
# 2. 拉取 Live555ProxyServerEx 源码
# ----------------------------------------------------
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
  Extended version of LIVE555 RTSP Proxy Server for OpenWrt.
endef

# 准备阶段：下载并解压 live555 源码到编译目录中
define Build/Prepare
	$(call Build/Prepare/Default)
	# 下载 Live555 源码
	$(SCRIPT_DIR)/download.pl "$(DL_DIR)" "$(LIVE555_SOURCE)" "x" "$(LIVE555_SITE)"
	# 解压到编译子目录 live/
	mkdir -p $(PKG_BUILD_DIR)/live
	$(TAR) -zxvf $(DL_DIR)/$(LIVE555_SOURCE) -C $(PKG_BUILD_DIR)/
endef

# 编译阶段：先交叉编译 Live555 静态库，再编译代理程序
define Build/Compile
	# 步骤 A: 交叉编译 LIVE555 基础库 (.a)
	cd $(PKG_BUILD_DIR)/live && \
		./genMakefiles linux && \
		$(MAKE) \
			CC="$(TARGET_CC)" \
			CXX="$(TARGET_CXX)" \
			CFLAGS="$(TARGET_CFLAGS)" \
			CXXFLAGS="$(TARGET_CXXFLAGS)"

	# 步骤 B: 编译 Live555ProxyServerEx 并静态链接 Live555
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

# 安装阶段：将生成的二进制文件放入 OpenWrt 系统的 /usr/bin/
define Package/live555ProxyServerEx/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/live555ProxyServerEx $(1)/usr/bin/
endef

$(eval $(call BuildPackage,live555ProxyServerEx))

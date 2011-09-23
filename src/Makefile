LUA     = lua-5.1.4
CFLAGS  = -fno-exceptions -fno-rtti -O2 -I$(LUA) -L$(LUA)
SRC     = main.cpp soap.cpp mem.cpp mcast.cpp luaxlib.cpp luaxcore.cpp

all:
	make -C $(LUA) CC=gcc a
	gcc $(CFLAGS) -DWITH_LIBUUID -o xupnpd $(SRC) -ldl -llua -lm -luuid
	strip xupnpd

mipsel:
	$(MAKE) embedded SDK=/usr/local/toolchain-mipsel_gcc3.4.6/mipsel-linux/bin

ar71xx:
	$(MAKE) embedded SDK=/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1/usr/mips-openwrt-linux/bin PATH=$(PATH):/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1/usr/libexec/gcc/mips-openwrt-linux-uclibc/4.3.3

ar71xx_ar9132:
	$(MAKE) embedded SDK=/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1-ar9132/usr/mips-openwrt-linux/bin PATH=$(PATH):/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1-ar9132/usr/libexec/gcc/mips-openwrt-linux-uclibc/4.3.3

ar71xx_trunk:
	$(MAKE) embedded SDK=/usr/local/toolchain-mips_r2_gcc-4.5-linaro_uClibc-0.9.32/mips-openwrt-linux/bin PATH=$(PATH):/usr/local/toolchain-mips_r2_gcc-4.5-linaro_uClibc-0.9.32/libexec/gcc/mips-openwrt-linux-uclibc/4.5.4


embedded:
	export PATH
	make -C $(LUA) CC=$(SDK)/gcc a
	$(SDK)/gcc $(CFLAGS) -DWITH_URANDOM -o xupnpd $(SRC) -lm -llua -ldl
	$(SDK)/strip xupnpd

clean:
	make -C $(LUA) clean
	rm -f $(LUA)/liblua.a
	rm -f xupnpd
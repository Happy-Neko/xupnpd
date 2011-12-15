LUA     = lua-5.1.4
CFLAGS  = -fno-exceptions -fno-rtti -O2 -I$(LUA) -L$(LUA)
SRC     = main.cpp soap.cpp mem.cpp mcast.cpp luaxlib.cpp luaxcore.cpp luajson.cpp luajson_parser.cpp

x86:
	make -C $(LUA) CC=gcc a
	gcc -O2 -c -o md5.o md5c.c
	gcc $(CFLAGS) -DWITH_LIBUUID -o xupnpd $(SRC) md5.o -llua -ldl -lm -luuid
	strip xupnpd

mipsel_ddwrt:
	$(MAKE) embedded TARGET=mipsel-ddwrt SDK=/usr/local/toolchain-mipsel_gcc3.4.6/mipsel-linux/bin

mipsel:
	$(MAKE) embedded TARGET=mipsel SDK=/usr/local/toolchain-mipsel_gcc-3.4.6_uClibc-0.9.30.1/usr/mipsel-openwrt-linux/bin PATH=$(PATH):/usr/local/toolchain-mipsel_gcc-3.4.6_uClibc-0.9.30.1/usr/libexec/gcc/mipsel-openwrt-linux-uclibc/3.4.6

ar71xx:
	$(MAKE) embedded TARGET=ar71xx SDK=/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1/usr/mips-openwrt-linux/bin PATH=$(PATH):/usr/local/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1/usr/libexec/gcc/mips-openwrt-linux-uclibc/4.3.3



embedded:
	export PATH
	make -C $(LUA) CC=$(SDK)/gcc a
	$(SDK)/gcc -O2 -c -o md5.o md5c.c
	$(SDK)/gcc $(CFLAGS) -DWITH_URANDOM -o xupnpd-$(TARGET) $(SRC) md5.o -lm -llua -ldl
	$(SDK)/strip xupnpd-$(TARGET)

clean:
	make -C $(LUA) clean
	rm -f $(LUA)/liblua.a
	rm -f md5.o

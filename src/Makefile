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
	$(MAKE) embedded SDK=/usr/local/toolchain-mips_gcc4.1.2/mips-linux/bin

embedded:
	make -C $(LUA) CC=$(SDK)/gcc a
	$(SDK)/gcc $(CFLAGS) -DWITH_URANDOM -o xupnpd $(SRC) -lm -llua -ldl
	$(SDK)/strip xupnpd

clean:
	make -C $(LUA) clean
	rm -f $(LUA)/liblua.a
	rm -f xupnpd
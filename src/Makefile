CFLAGS = -fno-exceptions -fno-rtti -O2 `pkg-config lua5.1 --cflags`

all:
	gcc $(CFLAGS) -o xupnpd main.cpp soap.cpp mem.cpp luaupnp.cpp luacore.cpp `pkg-config lua5.1 --libs` -ldl
	strip xupnpd

luaupnp:
	gcc $(CFLAGS) -fPIC -shared -o luaupnp.so luaupnp.cpp soap.cpp mem.cpp

luacore:
	gcc $(CFLAGS) -fPIC -shared -o luacore.so luacore.cpp

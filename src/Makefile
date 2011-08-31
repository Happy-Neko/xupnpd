CFLAGS = -fno-exceptions -fno-rtti -O2 `pkg-config lua5.1 --cflags`

all:
	gcc $(CFLAGS) -o xupnpd main.cpp soap.cpp mem.cpp mcast.cpp luaxlib.cpp luaxcore.cpp `pkg-config lua5.1 --libs` -ldl
	strip xupnpd

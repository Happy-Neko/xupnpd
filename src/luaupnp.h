#ifndef __LUAUPNP_H
#define __LUAUPNP_H

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}


extern "C" int luaopen_luaupnp(lua_State* L);


#endif

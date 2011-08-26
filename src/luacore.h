#ifndef __LUACORE_H
#define __LUACORE_H

extern "C"
{
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

namespace core
{
    extern int detached;
}

extern "C" int luaopen_luacore(lua_State* L);


#endif

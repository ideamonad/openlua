#include <stdio.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

static int
my_require (lua_State* L) 
{
   return 0;
}

int
main( int argc, char *argv[] )
{
    int i = 0;

    lua_State *L = lua_open();
    luaopen_base(L);
    luaopen_string(L);
    luaopen_table(L);
    luaopen_math(L);
    luaopen_io(L);
    luaopen_debug(L);
    luaopen_loadlib(L);
    luaopen_lfs(L);

    /* disable require function */
    lua_pushcfunction(L,my_require);
    lua_setglobal(L, "require");

#include "byte/common.inc"
#include "byte/set.inc"
#include "byte/list.inc"
#include "byte/stack.inc"
#include "byte/prototype.inc"
#include "byte/analyse.inc"
#include "byte/slr.inc"

    /* arg = {} */
    lua_pushstring(L,"arg");
    lua_newtable(L);

    for (i = 1; i < argc; ++i)
    {
        lua_pushstring(L, argv[i]);
        lua_rawseti(L,-2,i);
    }

    lua_settable(L,LUA_GLOBALSINDEX);

#include "byte/parse.inc"

    lua_close(L);
}


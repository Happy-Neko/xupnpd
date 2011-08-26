#include "luaupnp.h"
#include <string.h>
#include <stdio.h>
#include "soap.h"

static void lua_push_soap_node(lua_State* L,soap::node* node)
{
    lua_pushstring(L,node->name?node->name:"???");

    if(node->len>0)
        lua_pushlstring(L,node->data,node->len);
    else
    {
        lua_newtable(L);

        for(soap::node* p=node->beg;p;p=p->next)
            lua_push_soap_node(L,p);
    }

    lua_rawset(L,-3);
}

static int lua_soap_parse(lua_State* L)
{
    size_t l=0;

    const char* s=lua_tolstring(L,1,&l);
    if(!s)
        s="";

    lua_newtable(L);

    soap::node root;
    soap::ctx ctx(&root);

    ctx.begin();
    if(!ctx.parse(s,l) && !ctx.end() && root.beg)
        lua_push_soap_node(L,root.beg);

    root.clear();

    return 1;
}

static int lua_soap_find(lua_State* L)
{
    int top=lua_gettop(L);

    const char* s=lua_tostring(L,1);
    if(!s)
        s="";

    int depth=0;

    for(char *p1=(char*)s,*p2=0;p1;p1=p2)
    {
        if(lua_type(L,-1)!=LUA_TTABLE)
        {
            if(depth)
                lua_pop(L,1);

            lua_pushnil(L);
            break;
        }

        int l=0;
        p2=strchr(p1,'/');
        if(p2)
            { l=p2-p1; p2++; }
        else
            l=strlen(p1);
        if(l)
        {
            lua_pushlstring(L,p1,l);
            lua_gettable(L,-2);

            if(depth)
                lua_remove(L,-2);
        }

        depth++;
    }

    return 1;    
}


/*
t.name - name of playlist
t.size - number of elements
t.elements - array of elements
-------------
t.elements[i].name - element name
t.elements[i].url  - element url
*/
static int lua_m3u_parse(lua_State* L)
{
    const char* name=lua_tostring(L,1);
    if(!name)
        name="";

    const char* ext=strrchr(name,'.');

    if(!ext || strcasecmp(ext+1,"m3u"))
        return 0;

    FILE* fp=fopen(name,"r");

    if(!fp)
        return 0;
    else
    {
        lua_newtable(L);

        char playlist_name[64]="";

        {
            const char* fname=strrchr(name,'/');
            if(!fname)
                fname=name;
            else
                fname++;

            int n=ext-fname;

            if(n>=sizeof(playlist_name))
                n=sizeof(playlist_name)-1;
            memcpy(playlist_name,fname,n);
            playlist_name[n]=0;
        }

        lua_pushstring(L,"name");
        lua_pushstring(L,playlist_name);
        lua_rawset(L,-3);

        lua_pushstring(L,"elements");
        lua_newtable(L);
        int idx=1;

        char track_name[64]="";
        char track_url[256]="";

        char buf[256];
        while(fgets(buf,sizeof(buf),fp))
        {
            char* beg=buf;
            while(*beg && (*beg==' ' || *beg=='\t'))
                beg++;

            char* p=strpbrk(beg,"\r\n");
            if(p)
                *p=0;
            else
                p=beg+strlen(beg);

            while(p>beg && (p[-1]==' ' || p[-1]=='\t'))
                p--;
            *p=0;

            p=beg;

            if(!strncmp(p,"\xEF\xBB\xBF",3))    // skip BOM
                p+=3;

            if(!*p)
                continue;

            if(*p=='#')
            {
                p++;
                static const char tag[]="EXTINF:";
                if(!strncmp(p,tag,sizeof(tag)-1))
                {
                    p+=sizeof(tag)-1;
                    while(*p && *p==' ')
                        p++;

                    char* p2=strchr(p,',');
                    if(p2)
                    {
                        *p2=0;
                        p2++;

                        int n=snprintf(track_name,sizeof(track_name),"%s",p2);
                        if(n==-1 || n>=sizeof(track_name))
                            track_name[sizeof(track_name)-1]=0;
                    }
                }
            }else
            {
                int n=snprintf(track_url,sizeof(track_url),"%s",p);
                if(n==-1 || n>=sizeof(track_url))
                    track_url[sizeof(track_url)-1]=0;

                lua_pushinteger(L,idx++);

                lua_newtable(L);

                lua_pushstring(L,"name");
                lua_pushstring(L,track_name);
                lua_rawset(L,-3);

                lua_pushstring(L,"url");
                lua_pushstring(L,track_url);
                lua_rawset(L,-3);

                lua_rawset(L,-3);

                *track_name=0;
                *track_url=0;
            }
        }

        lua_rawset(L,-3);

        lua_pushstring(L,"size");
        lua_pushinteger(L,idx-1);
        lua_rawset(L,-3);

        fclose(fp);
    }

    return 1;
}


int luaopen_luaupnp(lua_State* L)
{
    static const luaL_Reg lib_soap[]=
    {
        {"parse",lua_soap_parse},
        {"find" ,lua_soap_find},
        {0,0}
    };

    static const luaL_Reg lib_m3u[]=
    {
        {"parse",lua_m3u_parse},
        {0,0}
    };

    luaL_register(L,"soap",lib_soap);
    luaL_register(L,"m3u",lib_m3u);

    return 0;
}

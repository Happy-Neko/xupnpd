#include "luaxlib.h"
#include <string.h>
#include <stdio.h>
#include "soap.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

namespace util
{
    int get_file_ext(const char* path,char* dst,int len)
    {
        static const unsigned char t[256]=
        {
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
            0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
            0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
            0x40, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
            0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
            0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f,
            0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
            0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
            0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
            0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,
            0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,
            0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,
            0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,
            0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
        };

        *dst=0;

        int n=strlen(path);
        if(!n)
            return 0;

        const char* p=path+n;

        while(p>path && p[-1]!='.' && p[-1]!='/' && p[-1]!='\\')
            p--;

        if(p==path || p[-1]!='.')
            return 0;

        n=strlen(p);
        if(n>=len)
            n=len-1;

        for(int i=0;i<n;i++)
            dst[i]=t[p[i]];
        
        dst[n]=0;

        return n;
    }

    char* url_decode(char* s)
    {
        static const unsigned char t[256]=
        {
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
        };

        char* ptr=s;

        unsigned char* d=(unsigned char*)s;

        while(*s)
        {
            if(*s=='+')
                *d=' ';
            else if(*s=='%')
            {
                if(!s[1] || !s[2])
                    break;

                unsigned char c1=t[s[1]];
                unsigned char c2=t[s[2]];

                if(c1==0xff || c2==0xff)
                    break;
                *d=((c1<<4)&0xf0)|c2;
                s+=2;
            }else if((unsigned char*)s!=d)
                *d=*s;
            
            s++;
            d++;
        }
        *d=0;

        return ptr;
    }
}

                    

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


static int lua_util_geturlinfo(lua_State* L)
{
    const char* www_root=lua_tostring(L,1);
    const char* www_url=lua_tostring(L,2);

    if(!www_root)
        www_root="./";

    if(!www_url || *www_url!='/')
        return 0;

    char url[512];
    int n=snprintf(url,sizeof(url),"%s",www_url);
    if(n<0 || n>=sizeof(url))
        return 0;

    for(char* p=url;*p;p++)
        if(*p=='\\')
            *p='/';

    if(strstr(url,"/../"))
        return 0;

    char* args=strchr(url,'?');
    if(args)
    {
        *args=0;
        args++;
    }else
        args=(char*)"";

    char path[512];

    char* p=url; while(*p=='/') p++;
    int l=strlen(www_root);
    if(l>0 && www_root[l-1]!='/')
        n=snprintf(path,sizeof(path),"%s/%s",www_root,p);
    else
        n=snprintf(path,sizeof(path),"%s%s",www_root,p);
    if(n<0 || n>=sizeof(path))
        return 0;

    lua_newtable(L);

    lua_pushstring(L,url);
    lua_setfield(L,-2,"url");

    lua_pushstring(L,"args");
    lua_newtable(L);
    for(char* p1=args,*p2;p1;p1=p2)
    {
        p2=strchr(p1,'&');
        if(p2)
        {
            *p2=0;
            p2++;
        }
        p=strchr(p1,'=');
        if(p)
        {
            *p=0;
            p++;
        }
        if(*p1 && *p)
        {
            lua_pushstring(L,p1);
            lua_pushstring(L,util::url_decode(p));
            lua_rawset(L,-3);
        }
    }
    lua_rawset(L,-3);

    lua_pushstring(L,path);
    lua_setfield(L,-2,"path");


    struct stat st;
    int rc=stat(path,&st);

    lua_pushstring(L,"type");
    if(rc)
        lua_pushstring(L,"none");
    else
    {
        if(S_ISREG(st.st_mode))
            lua_pushstring(L,"file");
        else if(S_ISDIR(st.st_mode))
            lua_pushstring(L,"dir");
        else
            lua_pushstring(L,"unk");
    }
    lua_rawset(L,-3);

    if(!rc)
    {
        if(S_ISREG(st.st_mode))
        {
            lua_pushstring(L,"length");
            lua_pushinteger(L,st.st_size);
            lua_rawset(L,-3);
        }
    }

    char ext[32];
    if(util::get_file_ext(url,ext,sizeof(ext))>0)
    {
        lua_pushstring(L,"ext");
        lua_pushstring(L,ext);
        lua_rawset(L,-3);
    }

    return 1;
}

static int lua_util_getfext(lua_State* L)
{
    char ext[32];
    util::get_file_ext(lua_tostring(L,1),ext,sizeof(ext));
    lua_pushstring(L,ext);
    return 1;
}

int luaopen_luaxlib(lua_State* L)
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

    static const luaL_Reg lib_util[]=
    {
        {"geturlinfo",lua_util_geturlinfo},
        {"getfext",lua_util_getfext},
        {0,0}
    };

    luaL_register(L,"soap",lib_soap);
    luaL_register(L,"m3u",lib_m3u);
    luaL_register(L,"util",lib_util);

    return 0;
}

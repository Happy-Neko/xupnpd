#include "luacore.h"
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <syslog.h>
#include <string.h>
#include <errno.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>

namespace core
{
    int detached=0;

    volatile int __sig_quit=0;
    volatile int __sig_alarm=0;
    volatile int __sig_child=0;
    volatile int __sig_usr1=0;
    volatile int __sig_usr2=0;

    int __sig_pipe[2]={-1,-1};

    char* parse_command_line(const char* cmd,char** dst,int n);

    void sig_handler(int n)
    {
        int e=errno;

        switch(n)
        {
        case SIGINT:
        case SIGQUIT:
        case SIGTERM:
            __sig_quit=1;
            break;
        case SIGALRM:
            __sig_alarm=1;
            break;
        case SIGCHLD:
            __sig_child=1;
            break;
        case SIGUSR1:
            __sig_usr1=1;
            break;
        case SIGUSR2:
            __sig_usr2=1;
            break;
        }

        send(__sig_pipe[1],"*",1,MSG_DONTWAIT);

        errno=e;
    }

    void process_event(lua_State* L,const char* name,int arg1)
    {
        lua_getglobal(L,"events");

        lua_getfield(L,-1,name);

        if(lua_type(L,-1)==LUA_TFUNCTION)
        {
            lua_pushstring(L,name);
            lua_pushinteger(L,arg1);
            if(lua_pcall(L,2,0,0))
            {
                if(!detached)
                    fprintf(stderr,"%s\n",lua_tostring(L,-1));
                else
                    syslog(LOG_INFO,"%s",lua_tostring(L,-1));
                lua_pop(L,1);
            }
        }else
            lua_pop(L,1);

        lua_pop(L,1);
    }

    void process_signals(lua_State* L)
    {
//printf("%i\n",lua_gettop(L));

        char buf[128];
        while(recv(__sig_pipe[0],buf,sizeof(buf),MSG_DONTWAIT)>0);

        if(__sig_usr1)
            { __sig_usr1=0; process_event(L,"SIGUSR1",0); }
        if(__sig_usr2)
            { __sig_usr2=0; process_event(L,"SIGUSR2",0); }

        if(__sig_child)
        {
            __sig_child=0;

            pid_t pid;
            int status=0;

            lua_getglobal(L,"childs");

            while((pid=wait3(&status,WNOHANG,0))>0)
            {
                int del=0;

                lua_pushinteger(L,pid);
                lua_gettable(L,-2);

                if(lua_type(L,-1)==LUA_TTABLE)
                {
                    del=1;

                    lua_getfield(L,-1,"event");

                    const char* event=lua_tostring(L,-1);
                    if(event)
                    {
                        if(WIFEXITED(status))
                            status=WEXITSTATUS(status);
                        else
                            status=128;
                                                
                        process_event(L,event,status);
                    }
                    lua_pop(L,1);
                }else
                {
                    // not found, internal?
                }

                lua_pop(L,1);

                if(del)
                {
                    lua_pushinteger(L,pid);
                    lua_pushnil(L);
                    lua_rawset(L,-3);    
                }
            }

            lua_pop(L,1);
        }        

        if(__sig_alarm)
        {
            __sig_alarm=0;
        }

//printf("%i\n",lua_gettop(L));
    }

}

static int lua_core_openlog(lua_State* L)
{
    const char* s=lua_tostring(L,1);
    const char* p=lua_tostring(L,2);

    if(!s)
        s="???";
    if(!p)
        p="";
    
    int f=LOG_SYSLOG;
    if(!strncmp(p,"local",5))
    {
        if(p[5]>47 && p[5]<56 && !p[6])
            f=((16+(p[5]-48))<<3);
    }else if(!strcmp(p,"daemon"))
        f=LOG_DAEMON;

    openlog(s,LOG_PID,f);
                                                    
    return 0;
}

static int lua_core_log(lua_State* L)
{
    char ss[512];
    int n=0;

    int count=lua_gettop(L);

    lua_getglobal(L,"tostring");

    for(int i=1;i<=count;i++)
    {
        lua_pushvalue(L,-1);
        lua_pushvalue(L,i);
        lua_call(L,1,1);

        size_t l=0;
        const char* s=lua_tolstring(L,-1,&l);
        if(s)
        {
            int m=sizeof(ss)-n;
            if(l>=m)
                l=m-1;

            memcpy(ss+n,s,l);
            n+=l;

            if(i<count)
            {
                if(n<sizeof(ss)-1)
                    ss[n++]=' ';
            }

        }
        lua_pop(L,1);
    }

    ss[n]=0;

    if(core::detached)
        syslog(LOG_INFO,"%s",ss);
    else
        fprintf(stdout,"%s\n",ss);

    return 0;
}

static int lua_core_detach(lua_State* L)
{
    pid_t pid=fork();
    if(pid==-1)
        return luaL_error(L,"can't fork process");
    else if(pid>0)
        exit(0);

    int fd=open("/dev/null",O_RDWR);
    if(fd>=0)
    {
        for(int i=0;i<3;i++)
            dup2(fd,i);
        close(fd);
    }else
        for(int i=0;i<3;i++)
            close(i);

    core::detached=1;
    lua_register(L,"print",lua_core_log);
    
    return 0;
}



static int lua_core_touchpid(lua_State* L)
{
    const char* s=lua_tostring(L,1);
    if(!s)
        return 0;

    FILE* fp=fopen(s,"r");
    if(fp)
        return luaL_error(L,"pid file already is exist");

    fp=fopen(s,"w");
    if(fp)
    {
        fprintf(fp,"%i",getpid());
        fclose(fp);
    }

    return 0;
}

// free(rc)!
char* core::parse_command_line(const char* cmd,char** dst,int n)
{
    char* s=strdup(cmd);

    int st=0;
    char* tok=0;
    int i=0;

    for(char* p=s;*p && i<n-1;p++)
    {
        switch(st)
        {
        case 0:
            if(*p==' ') continue;
            tok=p;
            if(*p=='\'' || *p=='\"') st=1; else st=2;
            break;
        case 1:
            if(*p=='\'' || *p=='\"')
                { *p=0; st=0; dst[i++]=tok+1; tok=0; }
            break;
        case 2:
            if(*p==' ')
                { *p=0; st=0; dst[i++]=tok; tok=0; }
            break;
        }
    }
    if(tok && i<n-1)
        dst[i++]=tok;

    dst[i]=0;

    return s;
}

static int lua_core_spawn(lua_State* L)
{
    const char* cmd=lua_tostring(L,1);
    const char* event=lua_tostring(L,2);

    int rc=0;

    if(!cmd || !event)
    {
        lua_pushinteger(L,rc);
        return 1;
    }

    pid_t pid=fork();

    if(pid!=-1)
    {
        if(!pid)
        {
            for(int i=0;i<sizeof(core::__sig_pipe)/sizeof(*core::__sig_pipe);i++)
                close(core::__sig_pipe[i]);

            int fd=open("/dev/null",O_RDWR);
            if(fd>=0)
            {
                for(int i=0;i<3;i++)
                    dup2(fd,i);
                close(fd);
            }else
                for(int i=0;i<3;i++)
                    close(i);

            char* argv[128];
            core::parse_command_line(cmd,argv,sizeof(argv)/sizeof(*argv));
            if(argv[0])
                execvp(argv[0],argv);
            exit(127);
        }else
        {
            rc=1;

            lua_getglobal(L,"childs");

            lua_pushinteger(L,pid);
            lua_newtable(L);

            lua_pushstring(L,"cmd");
            lua_pushstring(L,cmd);
            lua_rawset(L,-3);

            lua_pushstring(L,"event");
            lua_pushstring(L,event);
            lua_rawset(L,-3);

            lua_rawset(L,-3);

            lua_pop(L,1);
        }
    }


    lua_pushinteger(L,rc);

    return 1;
}

static int lua_core_mainloop(lua_State* L)
{
    using namespace core;

    if(__sig_quit)
        return 0;

    setsid();

    if(socketpair(PF_LOCAL,SOCK_STREAM,0,__sig_pipe))
        return luaL_error(L,"socketpair fail, cna't create signal pipe");

    struct sigaction action;
    sigset_t full_sig_set;

    memset((char*)&action,0,sizeof(action));
    sigfillset(&action.sa_mask);
    action.sa_handler=sig_handler;
    sigfillset(&full_sig_set);

    signal(SIGHUP,SIG_IGN);
    signal(SIGPIPE,SIG_IGN);
    sigaction(SIGINT,&action,0);
    sigaction(SIGQUIT,&action,0);
    sigaction(SIGTERM,&action,0);
    sigaction(SIGALRM,&action,0);
    sigaction(SIGUSR1,&action,0);
    sigaction(SIGUSR2,&action,0);
    sigaction(SIGCHLD,&action,0);

    sigprocmask(SIG_BLOCK,&full_sig_set,0);

    while(!__sig_quit)
    {
        fd_set fdset;
        FD_ZERO(&fdset);
        FD_SET(__sig_pipe[0],&fdset);
        int nfd=__sig_pipe[0]+1;

        sigprocmask(SIG_UNBLOCK,&full_sig_set,0);

        int rc=select(nfd,&fdset,0,0,0);

        sigprocmask(SIG_BLOCK,&full_sig_set,0);

        if(rc==-1)
        {
            if(errno==EINTR)
            {
                process_signals(L);
                continue;
            }else
                break;
        }else if(!rc)
            continue;

        if(FD_ISSET(__sig_pipe[0],&fdset))
            process_signals(L);

    }

    sigprocmask(SIG_UNBLOCK,&full_sig_set,0);


    signal(SIGTERM,SIG_IGN);
    signal(SIGCHLD,SIG_IGN);
    kill(0,SIGTERM);
                        
    for(int i=0;i<sizeof(__sig_pipe)/sizeof(*__sig_pipe);i++)
        close(__sig_pipe[i]);

    return 0;
}

int luaopen_luacore(lua_State* L)
{
    static const luaL_Reg lib_core[]=
    {
        {"detach",lua_core_detach},
        {"openlog",lua_core_openlog},
        {"log",lua_core_log},
        {"touchpid",lua_core_touchpid},
        {"spawn",lua_core_spawn},
        {"mainloop",lua_core_mainloop},
        {0,0}
    };

    luaL_register(L,"core",lib_core);

    lua_newtable(L);
    lua_setglobal(L,"events");

    lua_newtable(L);
    lua_setglobal(L,"childs");

    return 0;
}

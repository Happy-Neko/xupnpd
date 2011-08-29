cfg={}

cfg.pid_file="/home/shocker/staff/tsdemuxer/xupnpd/src/xupnpd.pid"
cfg.log_ident=arg[1] or "xupnpd"
cfg.log_facility="local0"

--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
core.touchpid(cfg.pid_file)


function ssdp_handler(what,from,msg)
    print(what,from,msg["REQ"][1])
--    ssdp.send("test",req["FROM"])
end

events["SIGUSR1"]=function (what) print(what) end
events["SSDP"]=ssdp_handler
events["www_event"]=function (what,req) print(what) end -- fork!
events["spawn_event"]=function (what,status) print(what,status) end
events["timer_event"]=function (what,sec) core.spawn("bash -c 'echo hi > /dev/null'","spawn_event") core.timer(sec,what) end

ssdp.init("eth0",1,1)

http.listen(4044,"www_event")
http.listen(4045,"www_event")

--core.timer(3,"timer_event")

print("start")

core.mainloop()

print("stop")

os.remove(cfg.pid_file)
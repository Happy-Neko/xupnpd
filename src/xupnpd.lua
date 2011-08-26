cfg={}

cfg.pid_file="/home/shocker/staff/tsdemuxer/xupnpd/src/xupnpd.pid"
cfg.log_ident=arg[1] or "xupnpd"
cfg.log_facility="local0"

--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
core.touchpid(cfg.pid_file)

events["SIGUSR1"]=function (what) print(what) end
events["SSDP"]=function (what,msg) print(what) end
events["spawn_event"]=function (what,status) print(what,status) end
events["timer_event"]=function (what,sec) core.spawn("bash -c 'echo hi > /dev/null'","spawn_event") core.timer(sec,what) end

-- ssdp.init("eth0",1,0)

core.timer(3,"timer_event")

print("start")

core.mainloop()

print("stop")

os.remove(cfg.pid_file)
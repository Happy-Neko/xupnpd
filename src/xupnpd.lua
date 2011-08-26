cfg={}

cfg.pid_file="/home/shocker/staff/tsdemuxer/xupnpd/src/xupnpd.pid"
cfg.log_ident=args[1]
cfg.log_facility="local0"

--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
core.touchpid(cfg.pid_file)

events["SIGUSR1"]=function (what) print(what) end
events["test_event"]=function (what,status) print(what,status) end

core.spawn("bash -c 'echo hi > /dev/null'","test_event")

print("start")

core.mainloop()

print("stop")

os.remove(cfg.pid_file)
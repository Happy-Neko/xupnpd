cfg={}

cfg.log_ident=arg[1] or "xupnpd"
cfg.pid_file="/home/shocker/staff/tsdemuxer/xupnpd/src/"..cfg.log_ident..".pid"
cfg.log_facility="local0"
cfg.mcast_if="eth0"
cfg.www_root="./www/"
cfg.http_port=4044

--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
core.touchpid(cfg.pid_file)

dofile('xupnpd_ssdp.lua')
dofile('xupnpd_http.lua')

print("start "..cfg.log_ident)

core.mainloop()

print("stop "..cfg.log_ident)

os.remove(cfg.pid_file)
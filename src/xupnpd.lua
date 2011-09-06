cfg={}

cfg.log_ident=arg[1] or "xupnpd"
cfg.pid_file="/home/shocker/staff/tsdemuxer/xupnpd/src/"..cfg.log_ident..".pid"
cfg.log_facility="local0"
cfg.mcast_if="eth0"
cfg.www_root="./www/"
cfg.http_port=4044

playlist=
{
    'example.m3u'
}

--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
--core.touchpid(cfg.pid_file)

dofile('xupnpd_m3u.lua')
dofile('xupnpd_ssdp.lua')
dofile('xupnpd_http.lua')

print("start "..cfg.log_ident)

--services.cds.Browse({['ObjectID']='0/1', ['BrowseFlag']='BrowseDirectChildren', ['StartingIndex']='0', ['RequestedCount']='3'})
--services.cds.Browse({['ObjectID']='0/1/1', ['BrowseFlag']='BrowseMetadata', ['StartingIndex']='0', ['RequestedCount']='0'})
services.cds.Search({['ObjectID']='0', ['StartingIndex']='0', ['RequestedCount']='3'})

core.mainloop()

print("stop "..cfg.log_ident)

--os.remove(cfg.pid_file)
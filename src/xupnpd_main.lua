--core.detach()
core.openlog(cfg.log_ident,cfg.log_facility)
--core.touchpid(cfg.pid_file)

dofile('xupnpd_mime.lua')
dofile('xupnpd_m3u.lua')
dofile('xupnpd_ssdp.lua')
dofile('xupnpd_http.lua')

print("start "..cfg.log_ident)

--services.cds.Browse({['ObjectID']='0/1', ['BrowseFlag']='BrowseDirectChildren', ['StartingIndex']='0', ['RequestedCount']='3'})
--services.cds.Browse({['ObjectID']='0/1/1', ['BrowseFlag']='BrowseMetadata', ['StartingIndex']='0', ['RequestedCount']='0'})
--services.cds.Search({['ContainerID']='0', ['StartingIndex']='0', ['RequestedCount']='3', ['SearchCriteria']='upnp:class derivedfrom \"object.item.videoItem\" and @refID exists false'})

core.mainloop()

print("stop "..cfg.log_ident)

--os.remove(cfg.pid_file)

if cfg.daemon==true then core.detach() end

core.openlog(cfg.log_ident,cfg.log_facility)

if cfg.daemon==true and cfg.embedded~=true then core.touchpid(cfg.pid_file) end

if cfg.embedded==true then cfg.debug=0 end

update_id=1

subscr={}

dofile('xupnpd_mime.lua')
dofile('xupnpd_m3u.lua')
dofile('xupnpd_ssdp.lua')
dofile('xupnpd_http.lua')

function subscribe(event,sid,callback,ttl)
    local s={}
    subscr[sid]=s

    s.event=event
    s.sid=sid
    s.callback=callback
    s.timestamp=os.time()
    s.ttl=ttl

    if cfg.debug>0 then print('subscribe: '..sid..', '..event..', '..callback) end

end

function unsubscribe(sid)
    if subscr[sid] then
        subscr[sid]=nil

        if cfg.debug>0 then print('unsubscribe: '..sid) end
    end
end

function subscr_gc(what,sec)

    local t=os.time()
    local g={}

    for i,j in pairs(subscr) do
        if os.difftime(t,j.timestamp)>=j.ttl then
            table.insert(g,i)
        end
    end

    for i,j in ipairs(g) do
        subscr[j]=nil

        if cfg.debug>0 then print('force unsubscribe (timeout): '..j) end
    end

    core.timer(sec,what)
end

function subscr_notify(event)

    local data=string.format('<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\"><e:property><SystemUpdateID>%d</SystemUpdateID></e:property></e:propertyset>',update_id)

    for i,j in pairs(subscr) do
        if j.event==event then

            if cfg.debug>0 then print('notify: '..j.callback..', '..event) end
            http.notify(j.callback,j.sid,data,update_id)

        end
    end
end

function reload_playlist()
    dofile('xupnpd_mime.lua')
    dofile('xupnpd_m3u.lua')
    update_id=update_id+1

    if update_id>100000 then update_id=1 end

    if cfg.debug>0 then print('reload playlist, update_id='..update_id) end

    core.fspawn(subscr_notify,'cds_event')
end

events['SIGUSR1']=reload_playlist
events['reload']=reload_playlist
events['subscribe']=subscribe
events['unsubscribe']=unsubscribe
events['subscr_gc']=subscr_gc

--services.cds.Browse({['ObjectID']='0/1', ['BrowseFlag']='BrowseDirectChildren', ['StartingIndex']='0', ['RequestedCount']='3'})
--services.cds.Browse({['ObjectID']='0/1/1', ['BrowseFlag']='BrowseMetadata', ['StartingIndex']='0', ['RequestedCount']='0'})
--services.cds.Search({['ContainerID']='0', ['StartingIndex']='0', ['RequestedCount']='2', ['SearchCriteria']='upnp:class derivedfrom \"object.item.videoItem\" and @refID exists false'})

if cfg.embedded==true then print=function () end end

print("start "..cfg.log_ident)

core.timer(300,'subscr_gc')

http.timeout(cfg.http_timeout)

core.mainloop()

print("stop "..cfg.log_ident)

if cfg.daemon==true and cfg.embedded~=true then os.remove(cfg.pid_file) end

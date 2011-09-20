if cfg.daemon==true then core.detach() end

core.openlog(cfg.log_ident,cfg.log_facility)

if cfg.daemon==true and cfg.embedded~=true then core.touchpid(cfg.pid_file) end

if cfg.embedded==true then cfg.debug=0 end


function clone_table(t)
    local tt={}
    for i,j in pairs(t) do
        tt[i]=j
    end
    return tt
end


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
    s.ttl=tonumber(ttl)
    s.seq=0

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

function subscr_notify(t)

    local tt={}
    table.insert(tt,'0,'..update_id)

    for i,j in ipairs(playlist_data.elements) do
        table.insert(tt,j.objid..','..update_id)
    end

    local data=string.format(
        '<e:propertyset xmlns:e=\"urn:schemas-upnp-org:event-1-0\"><e:property><SystemUpdateID>%s</SystemUpdateID><ContainerUpdateIDs>%s</ContainerUpdateIDs></e:property></e:propertyset>',
        update_id,table.concat(tt,','))

    for i,j in ipairs(t) do
        if cfg.debug>0 then print('notify: '..j.callback..', sid='..j.sid..', seq='..j.seq) end
        http.notify(j.callback,j.sid,data,j.seq)
    end
end

function reload_playlist()
    dofile('xupnpd_mime.lua')
    reload_playlists()
    update_id=update_id+1

    if update_id>100000 then update_id=1 end

    if cfg.debug>0 then print('reload playlist, update_id='..update_id) end

    if cfg.dlna_notify==true then
        local t={}

        for i,j in pairs(subscr) do
            if j.event=='cds_event' then
                table.insert(t, { ['callback']=j.callback, ['sid']=j.sid, ['seq']=j.seq } )
                j.seq=j.seq+1
            end
        end

        if table.maxn(t)>0 then
            core.fspawn(subscr_notify,t)
        end
    end
end

function set_child_status(pid,status)
    pid=tonumber(pid)
    if childs[pid] then
        childs[pid].status=status
        childs[pid].time=os.time()
    end
end

events['SIGUSR1']=reload_playlist
events['reload']=reload_playlist

if cfg.dlna_notify==true then
    events['subscribe']=subscribe
    events['unsubscribe']=unsubscribe
    events['subscr_gc']=subscr_gc
end

events['status']=set_child_status

if cfg.embedded==true then print=function () end end

print("start "..cfg.log_ident)

if cfg.dlna_notify==true then
    core.timer(300,'subscr_gc')
end

http.timeout(cfg.http_timeout)

core.mainloop()

print("stop "..cfg.log_ident)

if cfg.daemon==true and cfg.embedded~=true then os.remove(cfg.pid_file) end

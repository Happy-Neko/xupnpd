ssdp_msg_alive={}
ssdp_msg_byebye={}

function ssdp_msg(nt,usn,nts)
    return string.format(
        'NOTIFY * HTTP/1.1\r\n'..
        'HOST: 239.255.255.250:1900\r\n'..
        'CACHE-CONTROL: max-age=1800\r\n'..
        'LOCATION: %s\r\n'..
        'NT: %s\r\n'..
        'NTS: %s\r\n'..
        'Server: %s\r\n'..
        'USN: %s\r\n\r\n',
        ssdp_location,nt,nts,ssdp_server,usn
        )
end


ssdp_service_list=
{
'upnp:rootdevice',
'urn:schemas-upnp-org:device:MediaServer:1',
'urn:schemas-upnp-org:service:ContentDirectory:1',
'urn:schemas-upnp-org:service:ConnectionManager:1',
'urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1'
}

function ssdp_init(t,nts)
    local uuid='uuid:'..ssdp_uuid

    table.insert(t,ssdp_msg(ssdp_uuid2,ssdp_uuid2,nts))

    for i,s in ipairs(ssdp_service_list) do
        table.insert(t,ssdp_msg(s,ssdp_uuid2..'::'..s,nts))
    end

end                     

function ssdp_alive()
    for i,s in ipairs(ssdp_msg_alive) do
        ssdp.send(s)
    end
end

function ssdp_byebye()
    for i,s in ipairs(ssdp_msg_byebye) do
        ssdp.send(s)
    end
end

function ssdp_handler(what,from,msg)
    if msg.reqline[1]=='M-SEARCH' and msg['MAN']=='ssdp:discover' then
        local st=msg['ST']

        local resp=false

        if st=='ssdp:all' or st==ssdp_uuid2 then resp=true else
            for i,s in ipairs(ssdp_service_list) do
                if st==s then resp=true break end
            end
        end

        if resp then
            ssdp.send(string.format(
                'HTTP/1.1 200 OK\r\n'..
                'CACHE-CONTROL: max-age=1800\r\n'..
                'DATE: %s\r\n'..
                'EXT:\r\n'..
                'LOCATION: %s\r\n'..
                'Server: %s\r\n'..
                'ST: %s\r\n'..
                'USN: %s::%s\r\n\r\n',
                os.date('!%a, %d %b %Y %H:%M:%S GMT'),ssdp_location,ssdp_server,st,ssdp_uuid2,st),from)
        end
    end
end


events["SSDP"]=ssdp_handler
events["ssdp_timer"]=function (what,sec) ssdp_alive() core.timer(sec,what) end

ssdp.init(cfg.ssdp_interface,1,cfg.ssdp_loop,cfg.ssdp_debug)   -- interface, ttl, allow_loop, debug (0,1 or 2)

www_location='http://'..ssdp.interface()..':'..cfg.http_port
ssdp_location=www_location..'/dev.xml'
ssdp_uuid=core.uuid()
ssdp_uuid2='uuid:'..ssdp_uuid
ssdp_server='eXtensible UPnP agent'

ssdp_init(ssdp_msg_alive,'ssdp:alive')
ssdp_init(ssdp_msg_byebye,'ssdp:byebye')

ssdp_alive()
core.timer(15,"ssdp_timer")

table.insert(atexit,ssdp_byebye)

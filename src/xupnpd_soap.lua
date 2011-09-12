services={}
services.cds={}
services.cms={}
services.msr={}

function playlist_item_to_xml(id,parent_id,pls)
    if pls.elements then
        return string.format(
            '<container id=\"%s\" childCount=\"%i\" parentID=\"%s\" restricted=\"true\"><dc:title>%s</dc:title><upnp:class>object.container</upnp:class></container>',
            id,pls.size or 0,parent_id,util.xmlencode(pls.name))
    else
        local logo=''
        local artist=''
        local url=pls.url or ''

        if pls.logo then logo=string.format('<upnp:albumArtURI dlna:profileID=\"JPEG_TN\">%s</upnp:albumArtURI>',util.xmlencode(pls.logo)) end

        if pls.parent then
            if pls.mime[1]==1 then
                artist=string.format('<upnp:actor>%s</upnp:actor>',util.xmlencode(pls.parent.name))
            elseif pls.mime[1]==2 then
                artist=string.format('<upnp:artist>%s</upnp:artist>',util.xmlencode(pls.parent.name))
            end
        end

        if pls.path then
            url=www_location..'/stream?s='..util.urlencode(pls.objid)
        else
            if cfg.proxy>0 then
                if cfg.proxy>1 or pls.mime[1]==2 then
                    url=www_location..'/proxy?s='..util.urlencode(pls.objid)
                end
            end
        end

        return string.format(
            '<item id=\"%s" parentID=\"%s\" restricted=\"true\"><dc:title>%s</dc:title><upnp:class>%s</upnp:class>%s%s<res size=\"0\" protocolInfo=\"%s%s\">%s</res></item>',
            id,parent_id,util.xmlencode(pls.name),pls.mime[2],artist,logo,pls.mime[4],pls.dlna_extras,util.xmlencode(url))

    end
end

function get_playlist_item_parent(s)
    if s=='0' then return '-1' end

    local t={}

    for i in string.gmatch(s,'(%w+)/') do table.insert(t,i) end
    
    return table.concat(t,'/')    
end


function xml_serialize(r)
    local t={}

    for i,j in pairs(r) do
        table.insert(t,'<'..j[1]..'>')
        table.insert(t,j[2])
        table.insert(t,'</'..j[1]..'>')
    end

    return table.concat(t)
end

services.cds.schema='urn:schemas-upnp-org:service:ContentDirectory:1'

function services.cds.GetSystemUpdateID()
    return {{'Id',update_id}}
end

function services.cds.GetSortCapabilities()
    return {{'SortCaps','dc:title'}}
end

function services.cds.Browse(args)
    local items={}
    local count=0
    local total=0

    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0\">')
--    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">')

    local pls=find_playlist_object(args.ObjectID)

    if pls then

        if args.BrowseFlag=='BrowseMetadata' then
            table.insert(items,playlist_item_to_xml(args.ObjectID,get_playlist_item_parent(args.ObjectID),pls))
            count=1
            total=1
        else
            local from=tonumber(args.StartingIndex)
            local to=from+tonumber(args.RequestedCount)

            if to==from then to=from+pls.size end

            if pls.elements then
                for i,j in ipairs(pls.elements) do
                    if i>from and i<=to then
                        table.insert(items,playlist_item_to_xml(args.ObjectID..'/'..i,args.ObjectID,j))
                        count=count+1
                    end
                end
                total=pls.size
            end
        end

    end

    table.insert(items,'</DIDL-Lite>')

    return {{'Result',util.xmlencode(table.concat(items))}, {'NumberReturned',count}, {'TotalMatches',total}, {'UpdateID',update_id}}

end


function services.cds.Search(args)
    local items={}
    local count=0
    local total=0

    local from=tonumber(args.StartingIndex)
    local to=from+tonumber(args.RequestedCount)
    local what=util.upnp_search_object_type(args.SearchCriteria)

    if to==from then to=from+10000 end

    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\" xmlns:dlna=\"urn:schemas-dlna-org:metadata-1-0\">')
--    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">')

    local pls=find_playlist_object(args.ContainerID)

    if pls then
        function __search(id,parent_id,p)
            if p.elements then
                for i,j in pairs(p.elements) do
                    __search(id..'/'..i,id,j)
                end
            else
                if what==0 or p.mime[1]==what then
                    total=total+1

                    if total>from and total<=to then
                        table.insert(items,playlist_item_to_xml(id,parent_id,p))
                        count=count+1
                    end
                end
            end
        end

        __search(args.ContainerID,get_playlist_item_parent(args.ContainerID),pls)
    end

    table.insert(items,'</DIDL-Lite>')

--    print(xml_serialize({{'Result',util.xmlencode(table.concat(items))}, {'NumberReturned',count}, {'TotalMatches',total}, {'UpdateID',update_id}}))
    return {{'Result',util.xmlencode(table.concat(items))}, {'NumberReturned',count}, {'TotalMatches',total}, {'UpdateID',update_id}}

end


services.cms.schema='urn:schemas-upnp-org:service:ConnectionManager:1'

function services.cms.GetCurrentConnectionInfo(args)
    return {{'ConnectionID',0}, {'RcsID',-1}, {'AVTransportID',-1}, {'ProtocolInfo',''},
        {'PeerConnectionManager',''}, {'PeerConnectionID',-1}, {'Direction','Output'}, {'Status','OK'}}
end

function services.cms.GetProtocolInfo()
    local protocols={}

    for i,j in pairs(upnp_proto) do table.insert(protocols,j..'*') end

    return {{'Sink',''}, {'Source',table.concat(protocols,',')}}
end

function services.cms.GetCurrentConnectionIDs()
    return {{'ConnectionIDs',''}}
end


services.msr.schema='urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1'

function services.msr.IsAuthorized(args)
    return {{'Result',1}}
end

function services.msr.RegisterDevice(args)
    return nil
end

function services.msr.IsValidated(args)
    return {{'Result',1}}
end

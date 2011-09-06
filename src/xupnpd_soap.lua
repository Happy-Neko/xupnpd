services={}
services.cds={}
services.cms={}
services.msr={}

update_id=1

protocols=
{
    'http-get:*:video/avi:*',
    'http-get:*:video/x-ms-asf:*',
    'http-get:*:video/x-ms-wmv:*',
    'http-get:*:video/mp4:*',
    'http-get:*:video/mpeg:*',
    'http-get:*:video/mpeg2:*',
    'http-get:*:video/mp2t:*',
    'http-get:*:video/mp2p:*',
    'http-get:*:video/quicktime:*',
    'http-get:*:audio/x-aac:*',
    'http-get:*:audio/x-ac3:*',
    'http-get:*:audio/mpeg:*',
    'http-get:*:audio/x-ogg:*',
    'http-get:*:audio/x-ms-wma:*'
}

function playlist_item_to_xml(id,parent_id,pls)
    if pls.elements then
        return string.format(
            '<container id=\"%s\" childCount=\"%i\" parentID=\"%s\" restricted=\"true\"><dc:title>%s</dc:title><upnp:class>object.container</upnp:class></container>',
            id,pls.size or 0,parent_id,util.xmlencode(pls.name)
            )
    else
        return string.format(
            '<item restricted=\"true\" id=\"%s" parentID=\"%s\"><dc:title>%s</dc:title><res protocolInfo=\"http-get:*:video/avi:DLNA.ORG_OP=01\" size=\"0\">%s</res><upnp:class>object.item.videoItem</upnp:class></item>',
            id,parent_id,util.xmlencode(pls.name),pls.url or ''
            )
    end
end

function get_playlist_item_parent(s)
    if s=='0' then return '-1' end

    local t={}

    for i in string.gmatch(s,'(%w+)/') do table.insert(t,i) end
    
    return table.concat(t,'/')    
end


services.cds.schema='urn:schemas-upnp-org:service:ContentDirectory:1'

function services.cds.GetSystemUpdateID()
    return {['Id']=update_id}
end

function services.cds.GetSortCapabilities()
    return {['SortCaps']='dc:title'}
end

function services.cds.Browse(args)
    local items={}
    local count=0
    local total=0

    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">')

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

--    print(soap.serialize({['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total, ['UpdateID']=update_id}))
    return {['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total, ['UpdateID']=update_id}

end


function services.cds.Search(args)
    local items={}
    local count=0
    local total=0

    local from=tonumber(args.StartingIndex)
    local to=from+tonumber(args.RequestedCount)

    if to==from then to=from+10000 end

    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">')

    local pls=find_playlist_object(args.ContainerID)

    if pls then
        function __search(id,parent_id,p)
            if p.elements then
                for i,j in pairs(p.elements) do
                    __search(id..'/'..i,id,j)
                end
            else
-- if filter then
                total=total+1

                if total>from and total<=to then
                    table.insert(items,playlist_item_to_xml(id,parent_id,p))
                    count=count+1
                end

            end
        end

        __search(args.ObjectID,get_playlist_item_parent(args.ObjectID),pls)
    end

    table.insert(items,'</DIDL-Lite>')

    print(soap.serialize({['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total, ['UpdateID']=update_id}))
--    return {['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total, ['UpdateID']=update_id}

end


services.cms.schema='urn:schemas-upnp-org:service:ConnectionManager:1'

function services.cms.GetCurrentConnectionInfo(args)
    return {['ConnectionID']=0, ['RcsID']=-1, ['AVTransportID']=-1, ['ProtocolInfo']='', ['PeerConnectionManager']='', ['PeerConnectionID']=-1, ['Direction']='Output', ['Status']='OK'}
end

function services.cms.GetProtocolInfo()
    return {['Sink']='', ['Source']=table.concat(protocols,',')}
end

function services.cms.GetCurrentConnectionIDs()
    return {['ConnectionIDs']=''}
end


services.msr.schema='urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1'

function services.msr.IsAuthorized(args)
    return {['Result']=1}
end

function services.msr.RegisterDevice(args)
    return nil
end

function services.msr.IsValidated(args)
    return {['Result']=1}
end

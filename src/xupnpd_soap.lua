services={}
services.cds={}
services.cms={}
services.msr={}

function playlist_item_to_xml(id,parent_id,pls)
    if not pls.url then
        return string.format(
            '<container id=\"%s\" childCount=\"%i\" parentID=\"%s\" restricted=\"true\"><dc:title>%s</dc:title><upnp:class>object.container</upnp:class></container>',
            id,pls.size or 0,parent_id,util.xmlencode(pls.name)
            )
    else
        return string.format(
            '<item restricted=\"true\" id=\"%s" parentID=\"%s\"><dc:title>%s</dc:title><res protocolInfo=\"http-get:*:video/avi:DLNA.ORG_OP=01\" size=\"0\">%s</res><upnp:class>object.item.videoItem</upnp:class></item>',
            id,parent_id,util.xmlencode(pls.name),pls.url
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
end

function services.cds.GetSortCapabilities()
end

function services.cds.Browse(args)

    local pls=find_playlist_object(args.ObjectID)

    if not pls then return nil end

    local items={}
    local count=0
    local total=0

    table.insert(items,'<DIDL-Lite xmlns=\"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:upnp=\"urn:schemas-upnp-org:metadata-1-0/upnp/\">')

    if args.BrowseFlag=='BrowseMetadata' then
        table.insert(items,playlist_item_to_xml(args.ObjectID,get_playlist_item_parent(args.ObjectID),pls))
        count=1
        total=1
    else
        local from=tonumber(args.StartingIndex)
        local to=from+tonumber(args.RequestedCount)

        if to==from then to=from+pls.size end

        for i,j in ipairs(pls.elements) do
            if i>from and i<=to then
                table.insert(items,playlist_item_to_xml(args.ObjectID..'/'..i,args.ObjectID,j))
                count=count+1
            end
        end

        total=pls.size
    end

    table.insert(items,'</DIDL-Lite>')

--    print(soap.serialize({['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total}))
    return {['Result']=table.concat(items), ['NumberReturned']=count, ['TotalMatches']=total}

end

function services.cds.Search(args)
end


services.cms.schema='urn:schemas-upnp-org:service:ConnectionManager:1'

function services.cms.GetCurrentConnectionInfo(args)
end

function services.cms.GetProtocolInfo()
end

function services.cms.GetCurrentConnectionIDs()
end


services.msr.schema='urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1'

function services.msr.IsAuthorized(args)
end

function services.msr.RegisterDevice(args)
end

function services.msr.IsValidated(args)
end

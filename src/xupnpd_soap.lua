services={}
services.cds={}
services.cms={}
services.msr={}


-- urn:schemas-upnp-org:service:ContentDirectory:1

function services.cds.GetSystemUpdateID()
end

function services.cds.GetSortCapabilities()
end

function services.cds.Browse(args)
    for i,j in pairs(args) do
        print(i,j)
    end
end

function services.cds.Search(args)
end


-- urn:schemas-upnp-org:service:ConnectionManager:1

function services.cms.GetCurrentConnectionInfo(args)
end

function services.cms.GetProtocolInfo()
end

function services.cms.GetCurrentConnectionIDs()
end


-- urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1

function services.msr.IsAuthorized(args)
end

function services.msr.RegisterDevice(args)
end

function services.msr.IsValidated(args)
end

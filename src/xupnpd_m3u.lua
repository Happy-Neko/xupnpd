playlist_data={}
playlist_data.name='root'
playlist_data.size=0
playlist_data.elements={}

for i,j in ipairs(playlist) do

    local pls

    if type(j)=='table' then

        if string.find(j[1],'(.+).m3u$') then pls=m3u.parse(j[1]) else pls=m3u.scan(j[1]) end

        if pls then
            if j[2] then pls.name=j[2] end
            if j[3] then pls.acl=j[3] end
        end
    else
        if string.find(j,'(.+).m3u$') then pls=m3u.parse(j) else pls=m3u.scan(j) end
    end


    if pls then
        if cfg.debug>0 then print('load \''..pls.name..'\'') end

        local udpxy=cfg.udpxy_url..'/udp/'

        for ii,jj in ipairs(pls.elements) do

            jj.url=string.gsub(jj.url,'udp://@',udpxy,1)

            if not jj.type then jj.type=util.getfext(jj.url) end

            local m=mime[jj.type]

            if not m then jj.type='mpeg' m=mime[jj.type] end

            jj.mime=m

            if jj.dlna_extras and dlna_org_extras[jj.dlna_extras] then
                jj.dlna_extras=dlna_org_extras[jj.dlna_extras]
            else
                jj.dlna_extras=m[5]
            end

            jj.objid='0/'..i..'/'..ii

            jj.parent=pls

            if cfg.debug>1 then print('\''..jj.name..'\' '..jj.url..' <'..jj.mime[3]..'>') end

        end

        playlist_data.elements[i]=pls
        playlist_data.elements[i].id=i
        playlist_data.size=playlist_data.size+1
    end
end


function find_playlist_object(s)
    local pls=nil

    for i in string.gmatch(s,'([^/]+)') do
        if not pls then
            if i~='0' then return nil else pls=playlist_data end
        else
            if not pls.elements then return nil end            
            pls=pls.elements[tonumber(i)]
        end
    end
    return pls
end


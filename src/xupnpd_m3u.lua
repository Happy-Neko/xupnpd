playlist_data={}
playlist_data.name='root'
playlist_data.size=0
playlist_data.elements={}

for i,j in ipairs(playlist) do
    local pls=m3u.parse(j)

    if pls then
        local udpxy=cfg.udpxy_url..'/udp/'

        for ii,jj in ipairs(pls.elements) do

            jj.url=string.gsub(jj.url,'udp://@',udpxy,1)

            if not jj.type then jj.type=util.getfext(jj.url) end

            local m=mime[jj.type]

            if not m then jj.type='mpeg' m=mime[jj.type] end

            jj.mime=m
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


-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

function add_playlists_from_dir(dir_path,playlist,plist)

    local d=util.dir(dir_path)

    if d then
        local tt={}
        for i,j in ipairs(playlist) do
            local path=nil
            if type(j)=='table' then path=j[1] else path=j end
            tt[path]=j
        end

        for i,j in ipairs(d) do
            if string.find(j,'^[%w_]+%.m3u$') then
                local fname=dir_path..j
                if not tt[fname] then
                    table.insert(plist,fname)
                    if cfg.debug>0 then print('found unlisted playlist \''..fname..'\'') end
                end
            end
        end
    end
end

function reload_playlists()
    playlist_data={}
    playlist_data.name='root'
    playlist_data.size=0
    playlist_data.elements={}

    local plist=clone_table(playlist)

    add_playlists_from_dir(cfg.playlists_path,playlist,plist)
    if cfg.feeds_path~=cfg.playlists_path then add_playlists_from_dir(cfg.feeds_path,playlist,plist) end

    local groups={}

    for i,j in ipairs(plist) do

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
            if cfg.debug>0 then print('playlist \''..pls.name..'\'') end

            local udpxy=cfg.udpxy_url..'/udp/'

            for ii,jj in ipairs(pls.elements) do
                jj.url=string.gsub(jj.url,'udp://@',udpxy,1)

                if not jj.type then
                    if pls.type then
                        jj.type=pls.type
                    else
                        jj.type=util.getfext(jj.url)
                    end
                end

                if pls.plugin and not jj.plugin then jj.plugin=pls.plugin end

                if pls.dlna_extras and not jj.dlna_extras then jj.dlna_extras=pls.dlna_extras end
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


                if cfg.group==true then
                    local group_title=jj['group-title']
                    if group_title then
                        local group=groups[group_title]
                        if not group then
                            group={}
                            group.name=group_title
                            group.elements={}
                            group.size=0
                            group.virtual=true
                            groups[group_title]=group
                        end

                        local element=clone_table(jj)
                        element.parent=group
                        element.objid=nil
                        group.size=group.size+1
                        group.elements[group.size]=element
                    end
                end

            end

            playlist_data.elements[i]=pls
            playlist_data.elements[i].id=i
            playlist_data.elements[i].objid='0/'..i
            playlist_data.size=playlist_data.size+1
        end
    end

    if cfg.group==true then
        for i,j in pairs(groups) do

            if cfg.debug>0 then print('group \''..j.name..'\'') end

            playlist_data.size=playlist_data.size+1
            j.id=playlist_data.size
            j.objid='0/'..j.id
            playlist_data.elements[j.id]=j

            for ii,jj in ipairs(j.elements) do
                jj.objid='0/'..j.id..'/'..ii
            end
        end
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

reload_playlists()

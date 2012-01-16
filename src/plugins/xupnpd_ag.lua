-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- MP4-lo
-- MP4-hi (VIP)
cfg.ag_fmt='MP4-lo'

function ag_updatefeed(feed,friendly_name)
    return false
end

function ag_strip_url(url)
    local n=string.find(url,'#')
    if not n then return url end
    return string.sub(url,0,n-1)
end

function ag_sendurl(ag_url,range)

    local url=nil

    if plugin_sendurl_from_cache(ag_url,range) then return end

    local clip_page=plugin_download(ag_strip_url(ag_url))

    if clip_page then
        local playlist_id=string.match(clip_page,'http://video%.ag%.ru/playlist[%w_]*/(%w+)%.xml')
        clip_page=nil

        if playlist_id then
            local ss=''
            if cfg.ag_fmt=='MP4-hi' then ss='_vip' end

            clip_page=plugin_download(string.format('http://video.ag.ru/playlist%s/%s.xml',ss,playlist_id))
            if clip_page then
                url=string.match(clip_page,'<mp4>(.-)</mp4>')
                clip_page=nil
            end
        end
    else
        if cfg.debug>0 then print('AG clip is not found') end
    end

    if url then
        if cfg.debug>0 then print('AG Real URL: '..url) end

        plugin_sendurl(ag_url,url,range)
    else
        if cfg.debug>0 then print('AG Real URL is not found') end

        plugin_sendfile('www/corrupted.mp4')
    end
end

plugins['ag']={}
plugins.ag.sendurl=ag_sendurl
plugins.ag.updatefeed=ag_updatefeed

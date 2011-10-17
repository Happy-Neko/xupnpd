-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- 18 - 360p  (MP4,h.264/AVC)
-- 22 - 720p  (MP4,h.264/AVC)
-- 37 - 1080p (MP4,h.264/AVC)
youtube_fmt=22

function youtube_updatefeed(feed,feed_type)
    return false
end

function youtube_sendurl(youtube_url)

    local url=nil

    local clip_page=http.download(youtube_url)

    if clip_page then
        local stream_map=util.urldecode(string.match(clip_page,'url_encoded_fmt_stream_map=(.-)&amp;'))
        clip_page=nil

        if stream_map then
            for i in string.gmatch(stream_map,'([^,]+)') do
                local item={}
                for j in string.gmatch(i,'([^&]+)') do
                    local name,value=string.match(j,'(%w+)=(.+)')
                    item[name]=util.urldecode(value)
--                    print(name,util.urldecode(value))
                end
                if item['itag']==tostring(youtube_fmt) then
                    url=item['url']
                    break
                end
            end
        end
    else
        if cfg.debug>0 then print('YouTube Clip is not found') end
    end

    if url then
        if cfg.debug>0 then print('YouTube Real URL: '..url) end
        local rc,location=http.sendurl(url,1)

        if location then        -- loop?
            if cfg.debug>0 then print('YouTube Redirect URL: '..location) end
            http.sendurl(location,1)
        end
    else
        if cfg.debug>0 then print('YouTobe Real URL is not found (fmt='..youtube_fmt..')') end
    end
end

plugins['youtube']={}
plugins.youtube.sendurl=youtube_sendurl
plugins.youtube.updatefeed=youtube_updatefeed

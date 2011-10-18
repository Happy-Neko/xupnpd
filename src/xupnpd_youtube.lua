-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- 18 - 360p  (MP4,h.264/AVC)
-- 22 - 720p  (MP4,h.264/AVC)
-- 37 - 1080p (MP4,h.264/AVC)
youtube_fmt=22

-- top_rated, top_favorites, most_viewed, most_recent, recently_featured
function youtube_updatefeed(feed,feed_type)
    local rc=false

    local feed_url='http://gdata.youtube.com/feeds/mobile/standardfeeds/'..feed..'?alt=json&start-index=1&max-results=50'
    local feed_name='youtube_'..feed
    local feed_m3u_path='./playlists/'..feed_name..'.m3u'
    local tmp_m3u_path='/tmp/'..feed_name..'.m3u'

    local feed_data=http.download(feed_url)

    if feed_data then
        local x=json.decode(feed_data)

        feed_data=nil

        if x then
            local dfd=io.open(tmp_m3u_path,'w+')
            if dfd then
                dfd:write('#EXTM3U\n')

                for i,j in ipairs(x.feed.entry) do
                    local title=j.title['$t']

                    local url=nil
                    for ii,jj in ipairs(j.link) do
                        if jj['type']=='text/html' then url=jj.href break end
                    end

                    local logo=nil
                    for ii,jj in ipairs(j['media$group']['media$thumbnail']) do
                        if tonumber(jj['width'])<480 then logo=jj.url break end
                    end

                    dfd:write('#EXTINF:0 logo=',logo,' type=',feed_type,' plugin=youtube,',title,'\n',url,'\n')
                end

                dfd:close()

                if util.md5(tmp_m3u_path)~=util.md5(feed_m3u_path) then
                    if os.execute(string.format('mv %s %s',tmp_m3u_path,feed_m3u_path))==0 then
                        if cfg.debug>0 then print('YouTube feed \''..feed_name..'\' updated') end
                        rc=true
                    end
                else
                    util.unlink(tmp_m3u_path)
                end
            end
        end
    end

    return rc
end

function youtube_sendurl(youtube_url,range)

    local url=nil

    if plugin_sendurl_from_cache(youtube_url,range) then return end

    local clip_page=http.download(youtube_url)

    if clip_page then
        local stream_map=util.urldecode(string.match(clip_page,'url_encoded_fmt_stream_map=(.-)&amp;'))
        clip_page=nil

        local fmt=string.match(youtube_url,'&fmt=(%w+)$')

        if not fmt then fmt=youtube_fmt end

        if stream_map then
            local url_18=nil
            for i in string.gmatch(stream_map,'([^,]+)') do
                local item={}
                for j in string.gmatch(i,'([^&]+)') do
                    local name,value=string.match(j,'(%w+)=(.+)')
                    item[name]=util.urldecode(value)
--                    print(name,util.urldecode(value))
                end
                if item['itag']==tostring(fmt) then
                    url=item['url']
                    break
                elseif item['itag']=="18" then
                    url_18=item['url']
                end
            end
            if not url then url=url_18 end
        end
    else
        if cfg.debug>0 then print('YouTube Clip is not found') end
    end

    if url then
        if cfg.debug>0 then print('YouTube Real URL: '..url) end

        plugin_sendurl(youtube_url,url,range)
    else
        if cfg.debug>0 then print('YouTube Real URL is not found)') end
    end
end

plugins['youtube']={}
plugins.youtube.sendurl=youtube_sendurl
plugins.youtube.updatefeed=youtube_updatefeed

--youtube_updatefeed('top_rated','mp4')
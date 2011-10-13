-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- feed example: 'channel/hd'
function vimeo_feed_download(feed)

    local feed_url='http://vimeo.com/api/v2/'..feed..'/videos.json'
    local feed_name='vimeo_'..string.gsub(feed,'/','_',1)
    local feed_path='/tmp/'..feed_name..'.json'
    local feed_m3u_path='./playlists/'..feed_name..'.m3u'

--    if http.download(feed_url,feed_path)>0 then
        local fd=io.open(feed_path,'r')

        if fd then
            local x=json.decode(fd:read('*a'))

            if x then

                local dfd=io.open(feed_m3u_path,'w+')
                if dfd then
                    dfd:write('#EXTM3U\n')

                    for i,j in ipairs(x) do
                        dfd:write('#EXTINF:0 logo=',j.thumbnail_medium,' type=mp4 vimeo_id=',j.id,',',j.title,'\n',j.url,'\n')
                    end
                    dfd:close()
                end
            end

            fd:close()
        end        
--    end
end


function vimeo_sendurl(vimeo_id,vimeo_url)

    local url=nil

    local tmp_path='/tmp/vimeo_'..vimeo_id..'.html'

    if http.download(vimeo_url,tmp_path)>0 then
        local fd=io.open(tmp_path,'r')
        if fd then
            local sig,ts=string.match(fd:read('*a'),'"signature":"(%w+)","timestamp":(%w+),')
            fd:close()

            if sig and ts then

                local redirect_url=string.format('http://player.vimeo.com/play_redirect?clip_id=%s&sig=%s&time=%s&quality=hd&codecs=H264&type=moogaloop_local&embed_location=',vimeo_id,sig,ts)
                if cfg.debug>0 then print('Vimeo redirect URL: '..redirect_url) end

                local len,location=http.download(redirect_url,tmp_path)

                if location then
                    url=location
                    if cfg.debug>0 then print('Real Vimeo URL: '..url) end
                end

            end
        end
    end

    if url then
        http.sendurl(url)
    end
end

--vimeo_feed_download('channel/hd')
--vimeo_sendurl('30364356','http://vimeo.com/30364356')

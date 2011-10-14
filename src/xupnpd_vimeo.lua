-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- feed example: 'channel/hd'
function vimeo_feed_download(feed)

    local rc=false

    local feed_url='http://vimeo.com/api/v2/'..feed..'/videos.json'
    local feed_name='vimeo_'..string.gsub(feed,'/','_',1)
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

                for i,j in ipairs(x) do
                    dfd:write('#EXTINF:0 logo=',j.thumbnail_medium,' type=mp4 vimeo_id=',j.id,',',j.title,'\n',j.url,'\n')
                end
                dfd:close()

                if util.md5(tmp_m3u_path)~=util.md5(feed_m3u_path) then
                    if os.execute(string.format('mv %s %s',tmp_m3u_path,feed_m3u_path))==0 then
                        if cfg.debug>0 then print('Vimeo feed '..feed_name..' is updated') end
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


function vimeo_sendurl(vimeo_id,vimeo_url)

    local url=nil

    local clip_page=http.download(vimeo_url)

    if clip_page then
        local sig,ts=string.match(clip_page,'"signature":"(%w+)","timestamp":(%w+),')
        clip_page=nil

        if sig and ts then

            local redirect_url=string.format('http://player.vimeo.com/play_redirect?clip_id=%s&sig=%s&time=%s&quality=hd&codecs=H264&type=moogaloop_local&embed_location=',vimeo_id,sig,ts)
            if cfg.debug>0 then print('Vimeo Redirect URL: '..redirect_url) else print('Vimeo Redirect URL is not found') end

            local clip_page,location=http.download(redirect_url)

            if location then
                url=location
                if cfg.debug>0 then print('Vimeo Real URL: '..url) else print('Vimeo Real URL is not found') end
            end
        end
    else
        if cfg.debug>0 then print('Vimeo Clip '..vimeo_id..' is not found') end
    end

    if url then
        if cfg.debug>0 then print('Send Vimeo Clip: '..vimeo_id) end
        http.sendurl(url)
    end
end

--vimeo_feed_download('channel/hd')
--vimeo_sendurl('30364356','http://vimeo.com/30364356')

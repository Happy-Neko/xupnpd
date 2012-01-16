-- Copyright (C) 2011 Anton Burdinuk
-- clark15b@gmail.com
-- https://tsdemuxer.googlecode.com/svn/trunk/xupnpd

-- MP4-lo
-- MP4-hi
cfg.ivi_fmt='MP4-hi'

function ivi_updatefeed(feed,friendly_name)
    return false
end

function ivi_sendurl(ivi_url,range)

    local url=nil

    if plugin_sendurl_from_cache(ivi_url,range) then return end

    local ivi_id=string.match(ivi_url,'.+?id=(%w+)$')

    if not ivi_id then
        if cfg.debug>0 then print('Invalid IVI URL format, example - http://www.ivi.ru/video/view/?id=12345') end
        return
    end

    local clip_page=http.download('http://api.digitalaccess.ru/api/json',nil,
        string.format('{"method":"da.content.get","params":["%s",{"_domain":"www.ivi.ru","site":"1","test":1,"_url":"%s"}]}',ivi_id or '',ivi_url))

    if clip_page then
        local x=json.decode(clip_page)

        clip_page=nil

        if x.result and x.result.files then
            local url_lo=nil
            for i,j in ipairs(x.result.files) do
                if j.content_format==cfg.ivi_fmt then
                    url=j.url
                    break
                elseif j.content_format=='MP4-lo' then
                    url_lo=j.url
                end
            end
            if not url then url=url_lo end
        end
    else
        if cfg.debug>0 then print('IVI clip '..ivi_id..' is not found') end
    end

    if url then
        if cfg.debug>0 then print('IVI Real URL: '..url) end

        plugin_sendurl(ivi_url,url,range)
    else
        if cfg.debug>0 then print('IVI Real URL is not found') end

        plugin_sendfile('www/corrupted.mp4')
    end
end

plugins['ivi']={}
plugins.ivi.sendurl=ivi_sendurl
plugins.ivi.updatefeed=ivi_updatefeed

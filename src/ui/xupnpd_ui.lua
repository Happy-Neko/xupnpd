function ui_show_streams()
    for i,j in pairs(childs) do
        if j.status then
            http.send(j.status..'<br>\n')
        end
    end
end

function ui_clone_table(t)
    local tt={}
    for i,j in pairs(t) do
        tt[i]=j
    end
    return tt
end

ui_vars={}
ui_vars.streams=ui_show_streams

function ui_handler(args,data,ip)
    http_send_headers(200,'html')

    if not args.action then
        http.sendtfile('ui/ui_main.html',ui_vars)
    else
        if args.action=='upload' then
            local delimiter=string.match(data,'^(.-)[\r\n]')
            
            local body=string.match(data,delimiter..'[\r\n]+(.-)\r\n'..delimiter..'--[\r\n]*')
            delimiter=nil
            
            local hdr,content=string.match(body,'(.+)\r?\n\r?\n(.+)')
            body=nil 
            
            local fname=string.match(hdr,'filename=\"(.+)\"')
            hdr=nil

            local fd=io.open(fname,'w+')
            if fd then
                fd:write(content)
                fd:close()
            end

            local pls=m3u.parse(fname)

            function show_pls()
                if pls then
                    for i,j in ipairs(pls.elements) do
                        http.send(j.name..'<br>\n')
                    end
                end
            end

            local t=ui_clone_table(ui_vars)
            t.playlist=show_pls
            t.playlist_name=fname

            http.sendtfile('ui/ui_upload.html',t)
        end            
    end

end

function ui_handler(args,data,ip)
    http_send_headers(200,'html')

    if not args.action then
        http.sendtfile('ui/ui_main.html',{})
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

            local t={}

            if pls then
                for i,j in ipairs(pls.elements) do
                    table.insert(t,j.name)
                end
            end

            http.sendtfile('ui/ui_upload.html',{ ['fname']=fname, ['content']=table.concat(t,'<br>') })
        end            
    end

end

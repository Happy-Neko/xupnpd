function ui_show_streams()
    http.send('<table>\n')
    for i,j in pairs(childs) do
        if j.status then
            http.send('<tr><td>'..j.status..'</td></tr>\n')
        end
    end
    http.send('</table>\n')
end

function ui_clone_table(t)
    local tt={}
    for i,j in pairs(t) do
        tt[i]=j
    end
    return tt
end

ui_vars=ui_clone_table(http_vars)
ui_vars.streams=ui_show_streams
ui_vars.return_url='/ui'

function ui_handler(args,data,ip)
    http_send_headers(200,'html')

    if not args.action then
        http.sendtfile('ui/ui_main.html',ui_vars)
    else
        if args.action=='upload' then

            ui_vars.return_url='/ui?action=playlist'

            local tt=util.multipart_split(data)
            data=nil

            if tt and tt[1] then
                local n,m=string.find(tt[1],'\r?\n\r?\n')

                if n then
                    local fname=string.match(string.sub(tt[1],1,n-1),'filename=\"(.+)\"')

                    if fname then
                        local tfname='/tmp/'..fname

                        local fd=io.open(tfname,'w+')
                        if fd then
                            fd:write(string.sub(tt[1],m+1))
                            fd:close()
                        end

                        local pls=m3u.parse(tfname)

                        if pls then
                            function show_pls()
                                http.send('<table>\n')
                                for i,j in ipairs(pls.elements) do
                                    http.send('<tr><td>'..j.name..'</td></tr>\n')
                                end
                                http.send('</table>\n')
                            end

                            local t=ui_clone_table(ui_vars)
                            ui_vars.playlist=show_pls
                            ui_vars.playlist_name=pls.name
                            http.sendtfile('ui/ui_upload.html',ui_vars)
                            os.rename(tfname,fname)
                        else
                            http.sendtfile('ui/ui_error.html',ui_vars)
                            os.remove(tfname)
                        end
                    else
                        http.sendtfile('ui/ui_error.html',ui_vars)
                    end
                end
            end
        elseif args.action=='reload' then
            core.sendevent('reload')
            http.sendtfile('ui/ui_ok.html',ui_vars)
        elseif args.action=='playlist' then
   
   
            http.sendtfile('ui/ui_playlist.html',ui_vars)
   
   
        else
            http.sendtfile('ui/ui_'..args.action..'.html',ui_vars)
        end
    end
end

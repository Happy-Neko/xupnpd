ui_vars=clone_table(http_vars)
ui_vars.return_url='/ui'

function ui_handler(args,data,ip)

    if args.action=='style' then
        http_send_headers(200,'css')
        http.sendfile('ui/bootstrap-1.2.0.min.css')
        return
    end

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

                    if fname and string.find(fname,'.+%.m3u$') then
                        local tfname='/tmp/'..fname

                        local fd=io.open(tfname,'w+')
                        if fd then
                            fd:write(string.sub(tt[1],m+1))
                            fd:close()
                        end

                        local pls=m3u.parse(tfname)

                        if pls then
                            if os.execute(string.format('mv %s playlists/%s',tfname,fname))~=0 then
                                os.remove(tfname)
                                http.sendtfile('ui/ui_error.html',ui_vars)
                            else
                                core.sendevent('reload')
                                http.sendtfile('ui/ui_ok.html',ui_vars)
                            end
                        else
                            os.remove(tfname)
                            http.sendtfile('ui/ui_error.html',ui_vars)
                        end
                    else
                        http.sendtfile('ui/ui_error.html',ui_vars)
                    end
                end
            end
        elseif args.action=='reload' then
            core.sendevent('reload')
            http.sendtfile('ui/ui_ok.html',ui_vars)
        elseif args.action=='feeds' then
            update_feeds_async()
            http.sendtfile('ui/ui_ok.html',ui_vars)
        elseif args.action=='playlist' then

            function show_playlists()
                http.send('<table>\n')
                local d=util.dir('playlists')
                if d then
                    table.sort(d)
                    for i,j in ipairs(d) do
                        if string.find(j,'.+%.m3u$') then
                            local fname=util.urlencode(j)
                            http.send(string.format('<tr><td><a href=\'/ui?action=show&fname=%s\'>%s</a> [<a href=\'/ui?action=remove&fname=%s\'>x</a>]</td></tr>\n',fname,j,fname))
                        end
                    end
                end
                http.send('</table>\n')
            end
   
            ui_vars.playlists=show_playlists
            http.sendtfile('ui/ui_playlist.html',ui_vars)   
        elseif args.action=='show' then
            ui_vars.return_url='/ui?action=playlist'

            if not args.fname or not string.find(args.fname,'^[%w_]+%.m3u$') then
                http.sendtfile('ui/ui_error.html',ui_vars)
                return
            end

            local pls=m3u.parse('playlists/'..args.fname)

            if pls then
                function show_playlist()
                    http.send('<table>\n')
                    for i,j in ipairs(pls.elements) do
                        http.send('<tr><td>'..j.name..'</td></tr>\n')
                    end
                    http.send('</table>\n')
                end

                local t=clone_table(ui_vars)
                ui_vars.playlist=show_playlist
                ui_vars.playlist_name=pls.name
                http.sendtfile('ui/ui_show.html',ui_vars)
            else
                http.sendtfile('ui/ui_error.html',ui_vars)
            end
        elseif args.action=='remove' then
            ui_vars.return_url='/ui?action=playlist'

            if not args.fname or not string.find(args.fname,'^[%w_]+%.m3u$') then
                http.sendtfile('ui/ui_error.html',ui_vars)
                return
            end

            if os.remove('playlists/'..args.fname) then
                core.sendevent('reload')
                http.sendtfile('ui/ui_ok.html',ui_vars)
            else
                http.sendtfile('ui/ui_error.html',ui_vars)
            end
        elseif args.action=='status' then
            function ui_show_streams()
                http.send('<table>\n')
                for i,j in pairs(childs) do
                    if j.status then
                        http.send(string.format('<tr><td>%s [<a href=\'/ui?action=kill&pid=%s\'>x</a>]</td></tr>\n',j.status,i))
                    end
                end
                http.send('</table>\n')
            end

            ui_vars.streams=ui_show_streams

            http.sendtfile('ui/ui_status.html',ui_vars)

        elseif args.action=='kill' then
            ui_vars.return_url='/ui?action=status'

            if not args.pid or not childs[tonumber(args.pid)] then
                http.sendtfile('ui/ui_error.html',ui_vars)
            else
                util.kill(args.pid)
                http.sendtfile('ui/ui_ok.html',ui_vars)
            end
        else
            http.sendtfile('ui/ui_'..args.action..'.html',ui_vars)
        end
    end
end

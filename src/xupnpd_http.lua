function http_handler(what,from,port,msg)
    print(what,from,msg.reqline[1],msg.reqline[2])
    print(msg.data)
    http.send("HTTP/1.0 200 Ok\r\nConnection: close\r\nContent-Type: text/plain\r\n\r\nHello");
    local f=util.geturlinfo(cfg.www_root,msg.reqline[2])

    for i,j in pairs(f) do
        if i=='args' then
            for k,m in pairs(j) do
                print(i,k,m)
            end
        else
            print(i,j)
        end
    end
--    http.sendfile(msg.reqline[2])
    http.flush()
end

events["http"]=http_handler

http.listen(cfg.http_port,"http")

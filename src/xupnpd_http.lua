http_mime={}
http_err={}

-- http_mime types
http_mime['html']='text/html'
http_mime['htm']='text/html'
http_mime['xml']='text/xml'
http_mime['txt']='text/plain'
http_mime['jpg']='image/jpeg'
http_mime['png']='image/png'

-- http http_error list
http_err[100]='Continue'
http_err[101]='Switching Protocols'
http_err[200]='OK'
http_err[201]='Created'
http_err[202]='Accepted'
http_err[203]='Non-Authoritative Information'
http_err[204]='No Content'
http_err[205]='Reset Content'
http_err[206]='Partial Content'
http_err[300]='Multiple Choices'
http_err[301]='Moved Permanently'
http_err[302]='Moved Temporarily'
http_err[303]='See Other'
http_err[304]='Not Modified'
http_err[305]='Use Proxy'
http_err[400]='Bad Request'
http_err[401]='Unauthorized'
http_err[402]='Payment Required'
http_err[403]='Forbidden'
http_err[404]='Not Found'
http_err[405]='Method Not Allowed'
http_err[406]='Not Acceptable'
http_err[407]='Proxy Authentication Required'
http_err[408]='Request Time-Out'
http_err[409]='Conflict'
http_err[410]='Gone'
http_err[411]='Length Required'
http_err[412]='Precondition Failed'
http_err[413]='Request Entity Too Large'
http_err[414]='Request-URL Too Large'
http_err[415]='Unsupported Media Type'
http_err[500]='Internal Server http_error'
http_err[501]='Not Implemented'
http_err[502]='Bad Gateway'
http_err[503]='Out of Resources'
http_err[504]='Gateway Time-Out'
http_err[505]='HTTP Version not supported'


function http_send_headers(err,ext,len)
    http.send(
        string.format(
            "HTTP/1.0 %i %s\r\nServer: %s\r\nDate: %s\r\nContent-Type: %s\r\nConnection: close\r\n",
            err,http_err[err] or 'Unknown',ssdp_server,os.date('!%a, %d %b %Y %H:%M:%S GMT'),http_mime[ext] or 'application/x-octet-stream')
    )
    if len then http.send(string.format("Content-Length: %i\r\n",len)) end
    http.send("\r\n",len)
end

function http_handler(what,from,port,msg)

    local f=util.geturlinfo(cfg.www_root,msg.reqline[2])

    if not f or (msg.reqline[3]~='HTTP/1.0' and msg.reqline[3]~='HTTP/1.1') then
        http_send_headers(400)
        return
    end

    print(from..' '..msg.reqline[1]..' '..msg.reqline[2])

    if f.url=='soap' then
        -- process SOAP request
    else
        -- send static file
        if f.type=='none' then http_send_headers(404) return end
        if f.type~='file' then http_send_headers(403) return end

        http_send_headers(200,f.ext,f.length)
        http.sendfile(f.path)
        http.flush()
    end

end

events["http"]=http_handler

http.listen(cfg.http_port,"http")

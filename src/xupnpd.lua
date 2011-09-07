cfg={}

cfg.ssdp_interface="eth0"
cfg.ssdp_debug=0
cfg.ssdp_loop=1
cfg.http_port=4044
cfg.udpxy_url='http://192.168.1.1:4022'
cfg.log_facility="local0"
cfg.proxy=true

cfg.log_ident=arg[1] or "xupnpd"
cfg.pid_file="/var/tmp/"..cfg.log_ident..".pid"
cfg.www_root="./www/"

playlist=
{
    'example.m3u',
--    'butovocom_iptv.m3u',
--    'mozhay.m3u'
}

dofile('xupnpd_main.lua')

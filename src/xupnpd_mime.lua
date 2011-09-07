upnp_type=
{
    ['video'] = 1,
    ['audio'] = 2,
    ['image'] = 3
}

upnp_class=
{
    ['video']     = 'object.item.videoItem',
    ['audio']     = 'object.item.audioItem.musicTrack',
    ['container'] = 'object.container',
    ['folder']    = 'object.container.storageFolder'
}                


upnp_proto=
{
    ['avi']   = 'http-get:*:video/avi:',
    ['asf']   = 'http-get:*:video/x-ms-asf:',
    ['wmv']   = 'http-get:*:video/x-ms-wmv:',
    ['mp4']   = 'http-get:*:video/mp4:',
    ['mpeg']  = 'http-get:*:video/mpeg:',
    ['mpeg2'] = 'http-get:*:video/mpeg2:',
    ['mp2t']  = 'http-get:*:video/mp2t:',
    ['mp2p']  = 'http-get:*:video/mp2p:',
    ['mov']   = 'http-get:*:video/quicktime:',
    ['aac']   = 'http-get:*:audio/x-aac:',
    ['ac3']   = 'http-get:*:audio/x-ac3:',
    ['mp3']   = 'http-get:*:audio/mpeg:',
    ['ogg']   = 'http-get:*:audio/x-ogg:',
    ['wma']   = 'http-get:*:audio/x-ms-wma:'
}

--DLNA.ORG_PN, DLNA.ORG_OP, DLNA.ORG_CI, DLNA.ORG_FLAGS

dlna_org_extras=
{
    ['none']  = '*'
}

mime=
{
    ['avi']   = { upnp_type.video, upnp_class.video, 'video/avi',       upnp_proto.avi,   dlna_org_extras.none },
    ['asf']   = { upnp_type.video, upnp_class.video, 'video/x-ms-asf',  upnp_proto.asf,   dlna_org_extras.none },
    ['wmv']   = { upnp_type.video, upnp_class.video, 'video/x-ms-wmv',  upnp_proto.wmv,   dlna_org_extras.none },
    ['mp4']   = { upnp_type.video, upnp_class.video, 'video/mp4',       upnp_proto.mp4,   dlna_org_extras.none },
    ['mpeg']  = { upnp_type.video, upnp_class.video, 'video/mpeg',      upnp_proto.mpeg,  dlna_org_extras.none },
    ['mpeg2'] = { upnp_type.video, upnp_class.video, 'video/mpeg2',     upnp_proto.mpeg2, dlna_org_extras.none },
    ['mp2t']  = { upnp_type.video, upnp_class.video, 'video/mp2t',      upnp_proto.mp2t,  dlna_org_extras.none },
    ['mp2p']  = { upnp_type.video, upnp_class.video, 'video/mp2p',      upnp_proto.mp2p,  dlna_org_extras.none },
    ['mov']   = { upnp_type.video, upnp_class.video, 'video/quicktime', upnp_proto.mov,   dlna_org_extras.none },
    ['aac']   = { upnp_type.audio, upnp_class.audio, 'audio/x-aac',     upnp_proto.aac,   dlna_org_extras.none },
    ['ac3']   = { upnp_type.audio, upnp_class.audio, 'audio/x-ac3',     upnp_proto.ac3,   dlna_org_extras.none },
    ['mp3']   = { upnp_type.audio, upnp_class.audio, 'audio/mpeg',      upnp_proto.mp3,   dlna_org_extras.none },
    ['ogg']   = { upnp_type.audio, upnp_class.audio, 'application/ogg', upnp_proto.ogg,   dlna_org_extras.none },
    ['wma']   = { upnp_type.audio, upnp_class.audio, 'audio/x-ms-wma',  upnp_proto.wma,   dlna_org_extras.none }
}

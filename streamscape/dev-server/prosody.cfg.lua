-- Local-only XMPP test server for StreamScape KIM iOS work.
-- Domain kim.localtest.me (and every subdomain) resolves to 127.0.0.1 in public DNS,
-- so the iOS simulator reaches this container without editing /etc/hosts.

admins = { }
pidfile = "/var/run/prosody/prosody.pid"
log = { info = "*console" }

certificates = "certs"

modules_enabled = {
    "roster"; "saslauth"; "tls"; "disco"; "ping"; "time"; "version"; "uptime";
    "register"; "private"; "vcard4"; "vcard_legacy"; "pep"; "bookmarks";
    "blocklist"; "carbons"; "smacks"; "mam"; "csi_simple"; "cloud_notify";
    "admin_shell";
}

-- In-app sign-up lets Monal's Register screen be tested against this server.
allow_registration = true
c2s_require_encryption = true
authentication = "internal_hashed"
storage = "internal"

archive_expires_after = "1w"
default_archive_policy = true

https_ports = { 5281 }
http_ports = { }
http_external_url = "https://upload.kim.localtest.me:5281/"

VirtualHost "kim.localtest.me"

Component "conference.kim.localtest.me" "muc"
    modules_enabled = { "muc_mam" }

Component "upload.kim.localtest.me" "http_file_share"
    http_file_share_size_limit = 50 * 1024 * 1024


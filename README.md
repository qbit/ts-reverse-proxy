# ts-reverse-proxy

A generic one-to-one (one hostname to one backend) reverse proxy.

`ts-reversy-proxy` starts up and listenes on port `443`, when a connection
is made for the matching `-name`, an ACME certificate is requested and then
the connection is passed along to `-ip` at `-port`.

Crazy Ideas
===========

Things that may seem like a good idea but would be stupid to be implemented right now. Writing them down helps put our minds off them.

Newer on top.

-	Make it easy for developers to expose their local development web server for the internet. See ngrok. Example https://developer.github.com/webhooks/configuring/. Unfortunately, ngrok 1.0 is said to suck, but there's koding/tunnel. See https://github.com/koding/tunnel.
	-	public server that receives setup request from localhost client, get their secret, replies with ephemeral domain, then calls server.AddHost with the ephemeral domain.
	-	I initially thought about making it yet another extra build target for a _server. But that could be weird to use in practice. Seems like a better option is to add a parameter that says "localhost_tunnel = True" and every time we blaze run something, a tunnel is created and the URL is shown.
-	script that checks the license of external WORKSPACE repositories and makes sure they are kosher before we merge them.

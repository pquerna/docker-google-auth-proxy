# Google Auth Reverse Proxy

Based on [docker-apache2](https://github.com/pquerna/docker-apache2) and [mod_auth_openidc](https://github.com/pingidentity/mod_auth_openidc)

## Usage

### Prepare external values

* You need your `OIDC_CLIENT_ID` and `OIDC_CLIENT_SECRET` from the Google: https://developers.google.com/identity/protocols/OpenIDConnect#getcredentials
* You need to configure your `OIDC_REDIRECT_URI` with Google.  If you wanted to protect `https://app.example.com/`, you should set this value to `https://app.example.com/_oidc_redirect`
* You need to generate an `OIDC_CRYPTO_SECRET`. This can be completely random, but should be shared across clustered instances and ideally across process restarts.  You can generate a suitable value with `openssl rand -base64 32`. This is used by `mod_auth_openidc` to encrypt session cookies.

### Prepare configuration Volume

In this example, we are creating files under `/srv/google-auth` to be mounted as `/conf` inside the proxying container.  You can use any path you like for volume in the host.

In `/srv/google-auth` put `google-auth.conf`

```apache
Listen *:443
NameVirtualHost *:443

<VirtualHost *:443>
	ServerName app.example.com

	# Defaults, based on https://wiki.mozilla.org/Security/Server_Side_TLS#Apache
	Include /opt/conf/ssl-vhost.conf

	SSLCertificateFile      /conf/app.example.com.crt
	SSLCertificateChainFile /conf/app.example.com.ca.crt
	SSLCertificateKeyFile   /conf/app.example.com.key

	<Location />
		AuthType openid-connect
		OIDCScope "openid email"
		# replace example.com with your Google Apps domain
		Require claim hd:example.com
	</Location>
</VirtualHost>
```
Additionally add the respective `app.example.com.crt`, `app.example.com.ca.crt` and `app.example.com.key` to the volume as SSL certificates.


## Run using docker

## Run Using rkt
```sh
rkt run \
--net=host \
-e OIDC_CLIENT_ID=VALUE_FROM_GOOLE
-e OIDC_CLIENT_SECRET=VALUE_FROM_GOOLE
-e OIDC_CRYPTO_SECRET=RANDOM_VALUE
--volume volume-conf,kind=host,source=/srv/google-auth,readOnly=true \
docker://quay.io/scaleft/google-auth-proxy:latest
```


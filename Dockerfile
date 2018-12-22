FROM quay.io/steven_elleman/apache2.4.37:latest

# <your-client-id-administered-through-the-google-api-console>
ENV OIDC_CLIENT_ID REPLACE_ME

# <your-client-secret-administered-through-the-google-api-console>
ENV OIDC_CLIENT_SECRET REPLACE_ME

ENV OIDC_REDIRECT_URI https://www.example.com/oidc_redirect_uri

# set to a random value for execution, or the same value when using multiple instances.
ENV OIDC_CRYPTO_SECRET REPLACE_ME

ENV AUTH_OPENIDC_VERSION 2.3.9
# ENV AUTH_OPENIDC_HASH 0707ea4f4a623911ebdfbcc3df2491303edada50  v2.3.9.tar.gz

COPY auth_oidc.conf /modules.conf.d/

RUN mkdir -p /build
WORKDIR /build

RUN wget https://github.com/zmartzone/mod_auth_openidc/releases/download/v2.3.9/mod_auth_openidc-2.3.9.tar.gz

# cannot find the hash for 2.3.9
# RUN echo "${AUTH_OPENIDC_HASH}" >> /build/sha1.sum
# RUN sha1sum -c

RUN tar -xzf mod_auth_openidc-${AUTH_OPENIDC_VERSION}.tar.gz

# Original hash checking
# RUN wget https://github.com/pingidentity/mod_auth_openidc/archive/v1.8.6.tar.gz
# RUN echo "${AUTH_OPENIDC_HASH}" >> /build/sha1.sum
# RUN sha1sum -c
# RUN tar -xzf v${AUTH_OPENIDC_VERSION}.tar.gz

WORKDIR /build/mod_auth_openidc-${AUTH_OPENIDC_VERSION}

# Despite adding make to dev packages make is missing, added below
ENV DEV_PACKAGES ${DEV_PACKAGES} automake autoconf jansson-dev apache2-dev libcurl libpcre gawk build-base musl-dev lib gcc libc-dev jansson-dev
ENV RUNTIME_PACKAGES ${RUNTIME_PACKAGES} jansson curl libcurl
RUN apk update add ${DEV_PACKAGES} ${RUNTIME_PACKAGES}

# these packages worked when added here, not when added to dev or runtime packages
RUN apk add make gcc libc-dev jansson-dev

# ./autogen.sh: line 2: autoreconf: not found
RUN ./autogen.sh

# THIS SOLVED THE LIBCURL ISSUE
# https://github.com/zmartzone/mod_auth_openidc/issues/62
ENV CURL_CFLAGS='-I/usr/local/curl/include'
ENV CURL_LIBS '-L/usr/local/curl/lib -lcurl'
ENV JANSSON_CFLAGS='-I/usr/local/jansson/include'
ENV JANSSON_LIBS='-L/usr/local/jansson/lib -ljansson'
ENV CJOSE_CFLAGS='-I/usr/local/cjose/include'
ENV CJOSE_LIBS='-L/usr/local/cjose/lib -cjose'
ENV PCRE_CFLAGS='-I/usr/local/libpcre/include'
ENV PCRE_LIBS='-L/usr/local/libpcre/lib -libpcre'

ENV HIREDIS_CFLAGS='-I/usr/local/hiredis/include'
ENV HIREDIS_LIBS='-L/usr/local/hiredis/lib -libpcre'

RUN ./configure --with-apxs2=/usr/local/apache2/bin/apxs

# cjose missing but no alpine package found - how to get cjose from https://github.com/cisco/cjose/blob/master/include/cjose
RUN make && make install
RUN apk del ${DEV_PACKAGES}
WORKDIR /opt

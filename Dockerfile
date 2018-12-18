FROM quay.io/steven_elleman/apache2.4.37:latest

# <your-client-id-administered-through-the-google-api-console>
ENV OIDC_CLIENT_ID REPLACE_ME

# <your-client-secret-administered-through-the-google-api-console>
ENV OIDC_CLIENT_SECRET REPLACE_ME

ENV OIDC_REDIRECT_URI https://www.example.com/oidc_redirect_uri

# set to a random value for execution, or the same value when using multiple instances.
ENV OIDC_CRYPTO_SECRET REPLACE_ME

ENV AUTH_OPENIDC_VERSION 1.8.6
ENV AUTH_OPENIDC_HASH 0707ea4f4a623911ebdfbcc3df2491303edada50  v1.8.6.tar.gz

COPY auth_oidc.conf /modules.conf.d/

RUN mkdir -p /build
WORKDIR /build
RUN wget https://github.com/pingidentity/mod_auth_openidc/archive/v1.8.6.tar.gz
RUN echo "${AUTH_OPENIDC_HASH}" >> /build/sha1.sum
RUN sha1sum -c
RUN tar -xzf v${AUTH_OPENIDC_VERSION}.tar.gz

WORKDIR /build/mod_auth_openidc-${AUTH_OPENIDC_VERSION}

ENV DEV_PACKAGES ${DEV_PACKAGES} automake autoconf jansson-dev curl-dev
ENV RUNTIME_PACKAGES ${RUNTIME_PACKAGES} jansson curl
RUN apk --update add ${DEV_PACKAGES} ${RUNTIME_PACKAGES}
RUN ./autogen.sh
RUN ./configure --with-apxs2=/opt/bin/apxs
RUN make && make install
RUN apk del ${DEV_PACKAGES}

WORKDIR /opt

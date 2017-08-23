FROM alpine:3.6 AS build

ENV NODE_VERSION 8.4.0
ENV YARN_VERSION 0.27.5

RUN set -euxo pipefail \
    \
    && apk --update add --no-cache \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
    \
    # gpg keys listed at https://github.com/nodejs/node#release-team
    && for key in \
        9554F04D7259F04124DE6B476D5A82AC7E37093B \
        94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
        FD3A5288F042B6850C66B31F09FE44734EB7990E \
        71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
        DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
        B9AE9905FFD7803F25714661B63B535A4C206CA9 \
        C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
        56730D5401028683275BD23C23EFEFE93C4CFFFE \
        # yarn
        6A010C5166006599AA17F08146C2130DFD2497F5 \
      ; do \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
      done \
    \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    \
    && strip --strip-all /usr/local/bin/node

RUN curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
    && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
    && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
    && mkdir -p /opt/yarn \
    && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1


FROM alpine:3.6 as libs

COPY --from=build /usr/local/bin/node /usr/local/bin/
COPY --from=build /opt/yarn /opt/yarn

RUN set -euxo pipefail \
    \
    && echo '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories \
    && apk --update add upx@community \
    && scanelf --nobanner --needed /usr/local/bin/node | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' | xargs apk add --no-cache \
    \
    && upx -9 /usr/local/bin/node \
    && apk del --purge apk-tools upx \
    \
    && tar -cf lib.tar /lib/*.so.* \
    && tar -cf usr-lib.tar /usr/lib/*.so.*


FROM busybox

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL

COPY --from=libs /usr/local/bin/node /usr/local/bin/
COPY --from=libs /opt/yarn /opt/yarn
COPY --from=libs /*.tar /

RUN set -euxo pipefail \
    \
    && addgroup -g 1000 -S node \
    && adduser -u 1000 -H -s /sbin/nologin -D -S -G node node \
    \
    && tar -xf /lib.tar \
    && tar -xf /usr-lib.tar \
    \
    && rm -rf /bin /*.tar

USER node

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.schema-version="1.0" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL

ENTRYPOINT ["/usr/local/bin/node", "/opt/yarn/bin/yarn.js"]

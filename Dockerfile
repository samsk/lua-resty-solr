FROM debian:bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends wget gnupg ca-certificates lsb-release \
    && wget -O - https://openresty.org/package/pubkey.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/openresty.gpg \
    && echo "deb http://openresty.org/package/debian $(lsb_release -cs) openresty" | tee /etc/apt/sources.list.d/openresty.list \
    && apt-get update \
    && apt-get install -y openresty libtest-nginx-perl luarocks git make

RUN luarocks install lua-resty-openssl
#RUN luarocks install lua-resty-solr

CMD openresty -g 'daemon off;'

FROM alpine:3.15.4 as builder

ARG ReleaseApi="https://api.github.com/repos/cloudreve/Cloudreve/releases/latest"
ARG Arch="amd64"

WORKDIR /ProjectCloudreve

RUN apk update \
    && apk add tar gzip curl sed grep

RUN curl -L --max-redirs 10 -o ./cloudreve.tar.gz `curl -s "${ReleaseApi}" | sed -e 's/"/\n/g' | grep http | grep linux | grep ${Arch}`

RUN tar xzf ./cloudreve.tzr.gz

FROM alpine:3.15.4

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

#LABEL MAINTAINER="Xavier Niu"

WORKDIR /cloudreve

COPY --from=builder /ProjectCloudreve/cloudreve /cloudreve/

VOLUME ["/cloudreve/uploads", "/downloads", "/cloudreve/avatar", "/cloudreve/config", "/cloudreve/db"]

RUN echo ">>>>>> update dependencies" \
    && apk update \
    && apk add tzdata \
    && echo ">>>>>> set up timezone" \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && echo ">>>>>> fix cloudreve-main premission" \
    && chmod +x /cloudreve/cloudreve-main

EXPOSE 5212

ENTRYPOINT ["./cloudreve", "-c", "/cloudreve/config/conf.ini"]

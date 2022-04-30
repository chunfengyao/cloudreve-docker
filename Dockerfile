FROM ubuntu:22.04 as builder

ARG ReleaseApi="https://api.github.com/repos/cloudreve/Cloudreve/releases/latest"

WORKDIR /ProjectCloudreve

RUN apt update \
    && apt install -y tar gzip curl sed grep \
    && apt clean

RUN uname -m

RUN if [ "0$(uname -m)" = "0x86_64" ]; then export Arch="amd64" ;fi \
    && if [ "0$(uname -m)" = "0arm64" ] || [ "0$(uname -m)" = "0aarch64" ]; then export Arch="arm64" ;fi \
    && if [ "0$(uname -m)" = "0arm" ] || [ "0$(uname -m)" = "0armv7l" ]; then export Arch="arm" ;fi \
    && if [ "0$Arch" = "0" ]; then exit 5 ;fi \
    && curl -L --max-redirs 10 -o ./cloudreve.tar.gz `curl -s "${ReleaseApi}" | sed -e 's/"/\n/g' | grep http | grep linux | grep "${Arch}.tar"`

RUN tar xzf ./cloudreve.tar.gz

FROM ubuntu:22.04

ENV PUID=1000
ENV PGID=1000
ENV TZ="Asia/Shanghai"

WORKDIR /cloudreve

COPY --from=builder /ProjectCloudreve/cloudreve /cloudreve/

VOLUME ["/cloudreve/uploads", "/downloads", "/cloudreve/avatar", "/cloudreve/config", "/cloudreve/db"]

RUN echo ">>>>>> update dependencies"
RUN apt update \
    && apt install -y tzdata \
    && apt clean
RUN echo ">>>>>> set up timezone" \
    && cp /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone
RUN echo ">>>>>> fix cloudreve premission" \
    && chmod +rx /cloudreve/cloudreve

EXPOSE 5212

ENTRYPOINT ["./cloudreve", "-c", "/cloudreve/config/conf.ini"]

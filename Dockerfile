FROM --platform=linux/amd64 python:3.11.1-alpine

RUN apk add --no-cache --upgrade bash \
                                 docker \
                                 python3 \
                                 py3-pip \
                                 py3-wheel \
                                 python3-dev \
                                 linux-headers \
                                 pcre-dev \
                                 uwsgi-python3 \
                                 build-base \
                                 unzip \
                                 wget
                                 
WORKDIR /opt

ARG VERSION=${VERSION}

RUN wget https://github.com/seatable/seatable-admin-docs/releases/download/seatable-python-runner-${VERSION}/seatable-python-runner-${VERSION}.zip

RUN unzip seatable-python-runner-${VERSION}.zip

COPY ./rootfs /

WORKDIR /opt/seatable-python-runner

RUN pip3 install -r server_requirements.txt

CMD ["./entrypoint.sh"]

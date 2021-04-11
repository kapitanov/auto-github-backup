FROM alpine:latest

RUN apk add --update --no-cache bash tzdata git git-lfs python3 py-pip tzdata
RUN pip3 install github-backup && github-backup -v

COPY requirements.txt /opt/github-backup/requirements.txt
RUN pip3 install -r /opt/github-backup/requirements.txt

ARG TIME_ZONE=UTC
RUN echo "timezone=${TIME_ZONE}" && \
    cp /usr/share/zoneinfo/${TIME_ZONE} /etc/localtime && \
    echo "${TIME_ZONE}" >/etc/timezone

COPY upload.py /opt/github-backup/upload.py
RUN chmod +x /opt/github-backup/upload.py

COPY clean.py /opt/github-backup/clean.py
RUN chmod +x /opt/github-backup/clean.py

COPY entrypoint.sh /opt/github-backup/entrypoint.sh
RUN chmod +x /opt/github-backup/entrypoint.sh

ENV BACKUPS_DIR=/var/github-backup
CMD /opt/github-backup/entrypoint.sh run

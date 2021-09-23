FROM paperist/alpine-texlive-ja

RUN apk add bash git jq

RUN ["chmod", "+x", "/entrypoint.sh"]
ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

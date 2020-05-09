FROM alpine

LABEL version="1.0.0"
LABEL \
  "name"="github_actions_reposync" \
  "repository"="https://github.com/ns408/github_actions_reposync.git"

RUN apk --update --no-cache add \
  git

ADD *.sh /
ENTRYPOINT ["/entrypoint.sh"]

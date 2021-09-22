FROM ruby:2.7.1-alpine

RUN apk update && apk upgrade && apk add --update --no-cache build-base postgresql-dev libxml2-dev libxslt-dev

WORKDIR /code
COPY . /code
RUN bundle config set without 'development test'
RUN bundle install

EXPOSE 4567

ENTRYPOINT ["bundle", "exec", "puma", "-p", "4567", "-e", "production"]

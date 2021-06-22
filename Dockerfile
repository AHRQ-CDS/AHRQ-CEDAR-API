FROM ruby:2.7.1

WORKDIR /code
COPY . /code
RUN bundle install

EXPOSE 4567

ENTRYPOINT ["bundle", "exec", "puma", "-p", "4567", "-e", "production"]

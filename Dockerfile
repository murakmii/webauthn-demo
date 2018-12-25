FROM ruby:2.5.3-alpine

COPY Gemfile Gemfile.lock config.ru ./webauthn-demo/
COPY app ./webauthn-demo/app/

WORKDIR webauthn-demo

RUN apk update && apk add build-base ruby-dev && \
  bundle install --path=vendor/bundle --without development test

EXPOSE 80

ENTRYPOINT [ "bundle", "exec", "rackup", "-E", "production", "-o", "0.0.0.0", "-p", "80" ]

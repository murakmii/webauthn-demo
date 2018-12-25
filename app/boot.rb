require "bundler/setup"

require "base64"
require "json"
require "openssl"
require "securerandom"

require "bindata"
require "cbor"
require "sinatra/base"

require "./app/basic_configuration"
require "./app/helpers"
require "./app/relying_party"

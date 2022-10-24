# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'ffi'
require 'time'
require 'json'
require 'jwt'

require_relative 'esia/version'
require_relative 'esia/config'
require_relative 'esia/client_secret'
require_relative 'esia/bad_request'
require_relative 'esia/token'
require_relative 'esia/client'

# Base module for working with ESIA
module ESIA
  class << self
    def configuration
      @configuration ||= Config.new
    end

    def configure
      yield configuration
    end
  end
end

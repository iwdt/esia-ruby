# frozen_string_literal: true

module ESIA
  # Configuration for client
  class Config
    attr_accessor :client_id,
                  :certificate_path,
                  :private_key_path,
                  :base_url,
                  :oauth_path,
                  :marker_path,
                  :response_type,
                  :scope

    # Initialize new configuration instance
    def initialize(
      client_id: nil,
      certificate_path: nil,
      private_key_path: nil,
      base_url: 'https://esia.gosuslugi.ru',
      oauth_path: '/aas/oauth2/ac',
      marker_path: '/aas/oauth2/te',
      scope: 'fullname',
      response_type: 'code'
    )
      @client_id = client_id
      @certificate_path = certificate_path
      @private_key_path = private_key_path
      @response_type = response_type
      @base_url = base_url
      @oauth_path = oauth_path
      @marker_path = marker_path
      @scope = scope
    end

    def oauth2_url
      "#{base_url}#{oauth_path}"
    end

    def grant_url
      "#{base_url}#{marker_path}"
    end
  end
end

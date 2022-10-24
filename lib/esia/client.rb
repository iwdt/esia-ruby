# frozen_string_literal: true

module ESIA
  # Connection to ESIA
  class Client
    attr_reader :config

    # Initialize new connection to ESIA
    #
    # @param config [Config] configuration for connection to ESIA
    def initialize(config = ESIA.configuration)
      @config = config
    end

    def oauth2_uri(redirect_to:)
      uri = URI(config.oauth2_url)
      uri.query = build_oauth2_query_string(generate_client_secret, redirect_to)
      uri
    end

    def fetch_token(code:, redirect_to:)
      signer = generate_client_secret
      body = build_grant_body(signer, code: code, redirect_to: redirect_to)
      uri = URI(config.grant_url)
      uri.query = URI.encode_www_form(timestamp: signer.timestamp_formated)
      res = Net::HTTP.post_form uri, body

      case res
      when Net::HTTPSuccess
        Token.new JSON.parse(res.body)
      when Net::HTTPBadRequest
        raise_bad_request JSON.parse(res.body)
      else
        raise BadRequest
      end
    end

    def fetch_user(token:, params:)
      fetch_resource('/', token: token, params: params)
    end

    def fetch_contacts(token:, params:)
      fetch_resource('/ctts', token: token, params: params)
    end

    private

    def fetch_resource(path, token: nil, params: {})
      uri = build_resource_uri(token: token, path: path, params: params)
      req = Net::HTTP::Get.new(uri)
      req['Authorization'] = "Bearer #{token.access_token}"
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(req)
      end

      JSON.parse(res.body)
    end

    def build_resource_uri(token:, path:, params:)
      uri = URI("#{config.base_url}/rs/prns/#{token.decoded_token.sbj_id}#{path}")
      uri.query = URI.encode_www_form params
      uri
    end

    def build_grant_body(signer, code:, redirect_to:)
      {
        client_id: config.client_id, client_secret: signer.client_secret,
        code: code, state: signer.state,
        scope: config.scope, timestamp: signer.timestamp_formated,
        redirect_uri: redirect_to, grant_type: 'authorization_code',
        token_type: 'Bearer'
      }
    end

    def build_oauth2_query_string(signer, redirect_to)
      URI.encode_www_form(
        scope: config.scope,
        timestamp: signer.timestamp_formated,
        client_id: config.client_id, state: signer.state,
        client_secret: signer.client_secret, redirect_uri: redirect_to,
        response_type: config.response_type
      )
    end

    def generate_client_secret
      ClientSecret.generate(
        config.client_id,
        config.scope,
        config.private_key_path,
        config.certificate_path
      )
    end

    def raise_bad_request(body)
      raise BadRequest.new body['error_description'], body['error']
    end
  end
end

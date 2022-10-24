# frozen_string_literal: true

module ESIA
  # Access token
  class Token
    attr_reader :access_token,
                :refresh_token,
                :decoded_token,
                :token_metadata,
                :id_token,
                :state,
                :token_type,
                :expires_in

    DecodedToken = Struct.new(:nbf, :scope, :iss, :sid, :sbj_id, :exp, :iat, :client_id)
    TokenMetadata = Struct.new(:ver, :typ, :sbt, :alg)

    def initialize(raw)
      @raw = raw
      @access_token = @raw['access_token']
      @refresh_token = @raw['refresh_token']
      @id_token = @raw['id_token']
      @state = @raw['state']
      @token_type = @raw['token_type']
      @expires_in = @raw['expires_in']

      decoded_token, token_metadata = JWT.decode @access_token, nil, false

      @decoded_token = build_decoded_token decoded_token
      @token_metadata = build_token_metadata token_metadata
    end

    def to_s
      @raw.to_json
    end

    private

    def build_decoded_token(data)
      DecodedToken.new(
        data['nbf'],
        data['scope'],
        data['iss'],
        data['urn:esia:sid'],
        data['urn:esia:sbj_id'],
        data['exp'],
        data['iat'],
        data['client_id']
      )
    end

    def build_token_metadata(data)
      TokenMetadata.new(
        data['ver'],
        data['typ'],
        data['sbt'],
        data['alg']
      )
    end
  end
end

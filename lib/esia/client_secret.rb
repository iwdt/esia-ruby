# frozen_string_literal: true

module ESIA
  # Module to generating client secret
  module ClientSecret
    extend FFI::Library

    ffi_lib File.join(__dir__, '../../ext/esia/libesia.so')
    attach_function :create_client_secret, %i[string string string string], :string

    # Result object for generating a client secret
    class Result
      attr_reader :client_secret, :state, :timestamp, :timestamp_formated

      def initialize(client_secret:, state:, timestamp:)
        @client_secret = client_secret
        @state = state
        @timestamp = Time.parse URI.decode_www_form_component(timestamp)
        @timestamp_formated = @timestamp.strftime '%Y.%m.%d %T %z'
      end
    end

    class << self
      # @param [String] client_id
      # @param [String] scope
      # @param [String] private_key_path
      # @param [String] cerificate_path
      #
      # @return [Result]
      def generate(client_id, scope, private_key_path, cerificate_path)
        json = create_client_secret(
          client_id, scope, private_key_path, cerificate_path
        )

        data = JSON.parse(json)
        timestamp = data['timestamp']
        state = data['state']
        client_secret = data['client_secret']
        error = data['error']

        raise error if !error.nil? && !error.empty?

        Result.new(client_secret: client_secret, state: state, timestamp: timestamp)
      end
    end
  end
end

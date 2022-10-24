# frozen_string_literal: true

module ESIA
  # Connection to ESIA
  class BadRequest < StandardError
    attr_reader :code

    def initialize(message = 'Неизвестная ошибка на стороне ЕСИА', code = 'unknown')
      @code = code

      super message
    end
  end
end

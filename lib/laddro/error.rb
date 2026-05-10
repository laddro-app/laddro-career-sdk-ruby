module Laddro
  class APIError < StandardError
    attr_reader :status, :code

    def initialize(message, status, code = nil)
      super(message)
      @status = status
      @code = code
    end

    def auth_error?
      status == 401
    end

    def usage_limit_error?
      status == 402
    end

    def not_found?
      status == 404
    end
  end
end

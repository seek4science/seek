module ROCrate
  class Exception < RuntimeError
    attr_reader :cause

    def initialize(message, original_exception)
      @cause = original_exception
      super("#{self.class.name} - #{message}\n#{@cause.class.name} - #{@cause.message}")
      set_backtrace(@cause.backtrace)
    end
  end
end

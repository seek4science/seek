module Git
  class InvalidPathException < StandardError
    attr_reader :path
    def initialize(message = nil, path: nil)
      super(message)
      @path = path
    end
  end
end

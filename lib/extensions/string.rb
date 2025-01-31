module Extensions
  module String
    def normalize_trailing_slash
      self.end_with?('/') ? self : "#{self}/"
    end
  end
end

String.include Extensions::String
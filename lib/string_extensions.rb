module StringExtensions; end
String.class_eval do
  def normalize_trailing_slash
     self.end_with?('/') ? self : "#{self}/"
  end
end

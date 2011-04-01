# BioCatalogue: lib/object.rb

# From: http://ozmm.org/posts/try.html

class Object
  ##
  #   @person ? @person.name : nil
  # vs
  #   @person.try(:name)
  def try(method)
    send method if respond_to? method
  end

  #caller_method_name and parse_caller are from Dzone snippets.. is this a problem for licensing?
  def caller_method_name
    parse_caller(caller(2).first).last
  end

  def parse_caller(at)
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file   = Regexp.last_match[1]
      line   = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      [file, line, method]
    end
  end


  #Acts like super(), except sends to a method from an included module,
  #instead of to the super class. It only works for instance methods.
  def mixin_super *args, &block
    method         = caller_method_name.to_sym
    unbound_method = self.class.included_modules.find { |mod| mod.method_defined? method }.instance_method method
    unbound_method.bind(self).call *args, &block
  end
end

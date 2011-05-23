# BioCatalogue: lib/object.rb

# From: http://ozmm.org/posts/try.html

class Object
  #caller_method_name and parse_caller are from Dzone snippets
  # http://snippets.dzone.com/posts/show/2787
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
    method = caller_method_name.to_sym
    mixin = self.class.included_modules.find { |mod| mod.method_defined? method }
    raise NoMethodError.new "No mixin defining #{method}", method, args unless mixin
    unbound_method = mixin.instance_method method
    unbound_method.bind(self).call *args, &block
  end

  #instead of a and a.b and a.b.c and a.b.c.d?
  #try_block {a.b.c.d?}
  #in addition for being useful for nil's, works for any object that doesn't provide the required method
  #so instead of a.respond_to? :b? and a.b? try_block { a.b? }
  def try_block
    yield
  rescue NoMethodError, NameError
    nil
  end

end

Module.module_eval do
  def class_alias_method_chain name, feature
    singleton_class.instance_eval do
      alias_method_chain name, feature
    end
  end
end


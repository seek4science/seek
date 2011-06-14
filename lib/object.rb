# BioCatalogue: lib/object.rb

# From: http://ozmm.org/posts/try.html

class Object
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


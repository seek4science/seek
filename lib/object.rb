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
  rescue RuntimeError => e
    if e.message.to_s == "Called id for nil, which would mistakenly be 4 -- if you really wanted the id of nil, use object_id"
      nil
    else
      raise
    end
  end

end

Module.module_eval do
  def class_alias_method_chain name, feature
    singleton_class.instance_eval do
      alias_method_chain name, feature
    end
  end
end


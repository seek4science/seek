class Object
  #instead of a and a.b and a.b.c and a.b.c.d?
  #try_block {a.b.c.d?}
  #in addition for being useful for nil's, works for any object that doesn't provide the required method
  #so instead of a.respond_to? :b? and a.b? try_block { a.b? }
  def try_block
    yield
  rescue NoMethodError, NameError => e
    Rails.logger.warn("Expected exception in try_block{} #{e}")
    nil
  rescue RuntimeError => e
    Rails.logger.warn("Expected exception in try_block{} #{e}")
    if e.message.to_s == "Called id for nil, which would mistakenly be 4 -- if you really wanted the id of nil, use object_id"
      nil
    else
      raise
    end
  end

  # Disables all authorization enforcement within the block passed to this method.
  def disable_authorization_checks
    saved = $authorization_checks_disabled
    $authorization_checks_disabled = true
    yield
  ensure
    $authorization_checks_disabled = saved
  end
end

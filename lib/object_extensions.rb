module ObjectExtensions; end

class Object
  # Disables all authorization enforcement within the block passed to this method.
  def disable_authorization_checks
    saved = $authorization_checks_disabled
    $authorization_checks_disabled = true
    yield
  ensure
    $authorization_checks_disabled = saved
  end
end

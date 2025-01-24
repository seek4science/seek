class CookieConsent
  OPTIONS = %w(tracking embedding necessary).freeze

  def initialize(store)
    @store = store
  end

  def options=(opts)
    @store.permanent[:cookie_consent] = opts.split(',').select { |opt| OPTIONS.include?(opt) }.join(',')
  end

  def options
    (@store[:cookie_consent] || '').split(',').select { |opt| OPTIONS.include?(opt) }
  end

  def required?
    Seek::Config.require_cookie_consent
  end

  def given?
    !required? || options.any?
  end

  def allow_tracking?
    !required? || options.include?('tracking')
  end

  def allow_embedding?
    !required? || options.include?('embedding')
  end

  def allow_necessary?
    !required? || options.include?('necessary')
  end
end

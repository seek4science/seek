module CountryCodes
  # The codes without flags below were discovered using the following:
  # ISO3166::Country.all.collect(&:alpha2).uniq.compact.reject{ |c| File.exist?(Rails.root.join("app/assets/images/famfamfam_flags/#{c.downcase}.png")) }
  VALID_CODES_WITHOUT_FLAGS = ["MF", "SX", "AQ", "IM", "SS", "BQ", "CW", "JE", "GG", "BL"].freeze

  def self.country(code)
    return nil if code.nil?
    if country = ISO3166::Country[code]
      #may be better to use the locale, but currently using 'en' to remain consistent with previous behaviour
      country.translations['en']
    end

  end

  #always return the code, whether country is the name or already the code
  def self.force_code(country)
    return nil if country.nil?
    if country.length == 2
      code(country(country))
    else
      code(country)
    end
  end

  def self.code(country)
    return nil if country.nil?
    ISO3166::Country.find_country_by_any_name(country)&.alpha2
  end

  def self.valid_code?(code)
    ISO3166::Country[code].present?
  end

  def self.has_flag?(code)
    valid_code?(code) && VALID_CODES_WITHOUT_FLAGS.exclude?(code&.upcase)
  end
end
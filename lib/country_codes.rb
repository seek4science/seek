module CountryCodes
  # The codes below were discovered using the following:
  # `ISO3166::Country.all.map { |c| CountryCodes.code(c.name) }.uniq.compact.reject { |c| File.exist?(Rails.root.join("app/assets/images/famfamfam_flags/#{c}.png")) }`
  VALID_CODES_WITHOUT_FLAGS = %w(aq gg im je).freeze

  @@codes = Hash.new
  File.open(File.join(Rails.root, 'config', 'countries.tab')).each do |record|
    parts = record.split("\t")
    @@codes[parts[0]] = parts[1].strip
  end

  #puts "countries = " + @@codes.to_s

  def self.country(code)
    return nil if code.nil?
    @@codes[code.upcase]
  end

  def self.code(country)
    return nil if country.nil?
    c = nil
    @@codes.each do |key, val|
      if(country.downcase.strip == val.downcase)
        c = key.downcase
        break
      end
    end
    return c
  end

  def self.valid_code?(code)
    @@codes.key?(code)
  end

  def self.has_flag?(code)
    !VALID_CODES_WITHOUT_FLAGS.include?(code)
  end
end
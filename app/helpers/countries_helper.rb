module CountriesHelper
  def country_code(country)
    if country.downcase == 'great britain'
      code = 'gb'
    elsif %w(england wales scotland).include?(country.downcase)
      code = country
    elsif country.length > 2
      code = CountryCodes.code(country)
    else
      code = country if CountryCodes.valid_code?(country)
    end
    code
  end
end

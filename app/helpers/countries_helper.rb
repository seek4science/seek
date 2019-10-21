module CountriesHelper
  include ApplicationHelper

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

  def country_text_or_not_specified(country)
    Rails.cache.fetch("country-link-text-#{country}") do
      if country
        #convert code to country name
        if country.length == 2
          country = CountryCodes.country(country)
        else
          # valdate the country, and convert to correct case
          country = CountryCodes.country(CountryCodes.code(country))
        end
      end
      text_or_not_specified(country,link_as_country:true)
    end
  end
end

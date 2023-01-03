module CountriesHelper
  include ApplicationHelper

  def country_code(country)
    if country.downcase == 'great britain' || %w(england wales scotland).include?(country.downcase)
      code = 'gb'
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
      code = country_code(country) unless country.nil?
      text = text_or_not_specified(country)
      if code.present? && CountryCodes.valid_code?(code)
        text = '&nbsp;' + flag_icon(country) + link_to(text, country_path(code))
      end
      text.html_safe
    end
  end
end

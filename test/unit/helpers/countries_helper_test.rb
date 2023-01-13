require 'test_helper'

class CountriesHelperTest < ActionView::TestCase

  test 'country_text_or_not_specified' do
    text = country_text_or_not_specified('gb')
    assert_match /<a href="\/countries\/GB">United Kingdom<\/a>/,text
    assert_match /famfamfam_flags\/gb.png/, text

    #ignore case
    text = country_text_or_not_specified('GB')
    assert_match /<a href="\/countries\/GB">United Kingdom<\/a>/,text
    assert_match /famfamfam_flags\/gb.png/, text

    text = country_text_or_not_specified('Germany')
    assert_match /<a href="\/countries\/DE">Germany<\/a>/,text
    assert_match /famfamfam_flags\/de.png/, text

    text = country_text_or_not_specified('GERMANY')
    assert_match /<a href="\/countries\/DE">Germany<\/a>/,text
    assert_match /famfamfam_flags\/de.png/, text

    text = country_text_or_not_specified('Russian Federation')
    assert_match /<a href="\/countries\/RU">Russian Federation<\/a>/,text
    assert_match /famfamfam_flags\/ru.png/, text

    text = country_text_or_not_specified(nil)
    assert_match />Not specified<\/span>/,text

    #shouldn't happen, but fall back to treating as nil if not a defined value
    text = country_text_or_not_specified('zz')
    assert_match />Not specified<\/span>/,text
    assert_no_match /famfamfam_flags/, text
    assert_no_match /href/,text

    text = country_text_or_not_specified('Land of Oz')
    assert_match />Not specified<\/span>/,text
    assert_no_match /famfamfam_flags/, text
    assert_no_match /href/,text
  end
end
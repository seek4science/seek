require 'test_helper'

class HelpDictionaryTest < ActiveSupport::TestCase
  def setup
    @dic = Seek::Help::HelpDictionary.instance
  end


  test 'all_links' do
    refute_empty @dic.all_links
    assert_includes @dic.all_links, 'https://docs.seek4science.org/tech/investigation-checksum'
  end

  test 'help link' do
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum', @dic.help_link(:investigation_checksum)
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum', @dic.help_link('investigation_checksum')
    assert_equal 'https://docs.seek4science.org/help/user-guide/roles', @dic.help_link(:roles)
    assert_nil @dic.help_link(:funky_fish)
  end


  test 'check links' do
    fails = []
    WebMock.allow_net_connect!
    begin
      RestClient.head('https://www.google.com')
    rescue Exception => e
      skip '* Possible network issue - Skipping help link checks *'
    else
      @dic.all_links.each do |link|
        begin
          RestClient.head(link)
        rescue Exception => e
          fails << "Problem with link #{link} - #{e.message}"
        end
      end
      assert_empty fails, fails.join(', ')
    ensure WebMock.disable_net_connect!
    end

  end
end

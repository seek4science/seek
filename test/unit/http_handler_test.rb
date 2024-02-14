require 'test_helper'

class HttpHandlerTest < ActiveSupport::TestCase
  test 'is_slideshare_url' do
    assert Seek::DownloadHandling::HttpHandler.new('http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794').send(:is_slideshare_url?)
    assert Seek::DownloadHandling::HttpHandler.new('http://www.slideshare.net////mygrid//if-we-build-it-will-they-come-13652794').send(:is_slideshare_url?)
    assert Seek::DownloadHandling::HttpHandler.new('https://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794').send(:is_slideshare_url?)
    assert Seek::DownloadHandling::HttpHandler.new('http://www.slideshare.net/FAIRDOM/the-fairdom-commons-for-systems-biology?qid=c69db330-25d5-46eb-89e6-18a8491b369f&v=default&b=&from_search=1').send(:is_slideshare_url?)

    refute Seek::DownloadHandling::HttpHandler.new('http://www.slideshare.net/if-we-build-it-will-they-come-13652794').send(:is_slideshare_url?)
    refute Seek::DownloadHandling::HttpHandler.new('http://www.bbc.co.uk').send(:is_slideshare_url?)
    refute Seek::DownloadHandling::HttpHandler.new('fish soup').send(:is_slideshare_url?)
    refute Seek::DownloadHandling::HttpHandler.new(nil).send(:is_slideshare_url?)
    refute Seek::DownloadHandling::HttpHandler.new('ftp://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794').send(:is_slideshare_url?)
  end
end

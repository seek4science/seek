require 'test_helper'

class RenderersTest < ActiveSupport::TestCase
  test 'factory' do
    cb = Factory(:content_blob)
    cb.url = 'http://bbc.co.uk'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class
  end

  test 'blank renderer' do
    assert_equal '', Seek::Renderers::BlankRenderer.new.render
  end

  test 'slideshare_renderer' do
    cb = Factory(:content_blob)

    cb.url = 'http://fish.com'
    renderer = Seek::Renderers::SlideshareRenderer.new(cb)
    refute renderer.can_render?

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794/'
    assert Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'http://www.slideshare.net////mygrid//if-we-build-it-will-they-come-13652794'
    assert Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'https://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    assert Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'http://www.slideshare.net/FAIRDOM/the-fairdom-commons-for-systems-biology?qid=c69db330-25d5-46eb-89e6-18a8491b369f&v=default&b=&from_search=1'
    assert Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'http://www.slideshare.net/if-we-build-it-will-they-come-13652794'
    refute Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'http://www.bbc.co.uk'
    refute Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'fish soup'
    refute Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = nil
    refute Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'ftp://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    refute Seek::Renderers::SlideshareRenderer.new(cb).can_render?

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'

    slideshare_api_url = "http://www.slideshare.net/api/oembed/2?url=#{cb.url}&format=json"
    mock_remote_file("#{Rails.root}/test/fixtures/files/slideshare.json",
                     slideshare_api_url,
                     'Content-Type' => 'application/json')

    renderer = Seek::Renderers::SlideshareRenderer.new(cb)
    assert renderer.can_render?

    html = renderer.render
    refute_nil html
    assert html =~ /iframe/
    assert html =~ /iframe/

    renderer = Seek::Renderers::SlideshareRenderer.new(nil)
    assert_equal '', renderer.render
  end

  test 'youtube renderer' do
    cb = Factory(:content_blob)

    cb.url = 'http://fish.com'
    renderer = Seek::Renderers::YoutubeRenderer.new(cb)
    refute renderer.can_render?

    cb.url = 'https://www.youtube.com/watch?v=1234abcd'
    assert Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://youtu.be/1234abcd'
    assert Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://www.youtube.com/embed/1234abcd'
    assert Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://www.youtube.com/v/1234abcd'
    assert Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://www.youtube.com/v/'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://www.youtu.be'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'http://www.slideshare.net/if-we-build-it-will-they-come-13652794'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'http://www.bbc.co.uk'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'fish soup'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = nil
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'ftp://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    refute Seek::Renderers::YoutubeRenderer.new(cb).can_render?

    cb.url = 'https://www.youtube.com/watch?v=1234abcd'
    renderer = Seek::Renderers::YoutubeRenderer.new(cb)
    assert renderer.can_render?

    ['https://www.youtube.com/watch?v=1234abcd', 'https://youtu.be/1234abcd',
     'https://www.youtube.com/embed/1234abcd', 'https://www.youtube.com/v/1234abcd'].each do |url|
      stub_request(:head, url).to_timeout
      cb = Factory(:content_blob, url: url)
      assert_equal "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube.com/embed/1234abcd\" frameborder=\"0\" allowfullscreen></iframe>",
                   Seek::Renderers::YoutubeRenderer.new(cb).render
    end

    html = renderer.render
    refute_nil html
    assert html =~ /iframe/

    renderer = Seek::Renderers::YoutubeRenderer.new(nil)
    assert_equal '', renderer.render
  end
end

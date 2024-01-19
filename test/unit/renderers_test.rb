require 'test_helper'

class RenderersTest < ActiveSupport::TestCase
  include HtmlHelper
  include Rails::Dom::Testing::Assertions

  setup do
    @asset = FactoryBot.create(:sop)
    @git = FactoryBot.create(:git_version)
  end

  test 'factory' do
    cb = FactoryBot.create(:content_blob)
    cb.url = 'http://bbc.co.uk'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class

    cb = FactoryBot.create(:content_blob)
    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class

    factory = Seek::Renderers::RendererFactory.instance
    assert_equal Seek::Renderers::PdfRenderer, factory.renderer(FactoryBot.create(:pdf_content_blob)).class
    assert_equal Seek::Renderers::PdfRenderer, factory.renderer(FactoryBot.create(:docx_content_blob)).class
    assert_equal Seek::Renderers::MarkdownRenderer, factory.renderer(FactoryBot.create(:markdown_content_blob)).class
    assert_equal Seek::Renderers::NotebookRenderer, factory.renderer(FactoryBot.create(:jupyter_notebook_content_blob)).class
    assert_equal Seek::Renderers::TextRenderer, factory.renderer(FactoryBot.create(:txt_content_blob)).class
    assert_equal Seek::Renderers::ImageRenderer, factory.renderer(FactoryBot.create(:image_content_blob)).class
    assert_equal Seek::Renderers::BlankRenderer, factory.renderer(FactoryBot.create(:binary_content_blob)).class
  end

  test 'factory cache' do
    cb = FactoryBot.create(:content_blob)
    cb.url = 'http://bbc.co.uk'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class
   
    cb.url = 'http://bbc.co.uk'
    cb.save!
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class
   
    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    cb.save!
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class
    
    # Tests with content blob having no content (cache key is different currently)
    cb = FactoryBot.create(:url_content_blob)
    cb.url = 'http://bbc.co.uk'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class
   
    cb.url = 'http://bbc.co.uk'
    cb.save!
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class
   
    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    cb.save!
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class
  end

  test 'blank renderer' do
    assert_equal '', Seek::Renderers::BlankRenderer.new(nil).render
  end

  test 'slideshare_renderer' do
    cb = FactoryBot.create(:content_blob)

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
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @git.add_remote_file('slide.html', 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794')
    gb = @git.get_blob('slide.html')
    renderer = Seek::Renderers::SlideshareRenderer.new(gb)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    renderer = Seek::Renderers::SlideshareRenderer.new(nil)
    assert_equal '', renderer.render
  end

  test 'youtube renderer' do
    cb = FactoryBot.create(:content_blob)
    renderer = Seek::Renderers::YoutubeRenderer.new(cb)

    valid_youtube_urls = %w(
    https://www.youtube.com/watch?v=1234abcd
    https://youtu.be/1234abcd
    https://www.youtube.com/embed/1234abcd
    https://www.youtube.com/v/1234abcd
    https://youtu.be/XOiKXxDmDDQ?list=ABC123XYZQQQ
    http://www.youtube.com/watch?v=XOiKXxDmDDQ&feature=youtu.be
    http://youtu.be/XOiKXxDmDDQ&feature=channel
    http://www.youtube.com/ytscreeningroom?v=XOiKXxDmDDQ
    http://www.youtube.com/embed/XOiKXxDmDDQ?rel=0
    http://youtube.com/?v=XOiKXxDmDDQ&feature=channel
    http://youtube.com/?feature=channel&v=XOiKXxDmDDQ
    http://youtube.com/?vi=XOiKXxDmDDQ&feature=channel
    http://youtube.com/watch?v=XOiKXxDmDDQ&feature=channel
    http://youtube.com/watch?vi=XOiKXxDmDDQ&feature=channel
    https://m.youtube.com/watch?v=XOiKXxDmDDQ
    https://www.youtube.com/watch?app=desktop&v=XOiKXxDmDDQ
    https://m.youtube.com/watch?app=desktop&v=XOiKXxDmDDQ).freeze

    invalid_youtube_urls = %w(http://fish.com
    https://www.youtube.com/v/
    https://www.youtu.be
    http://www.slideshare.net/if-we-build-it-will-they-come-13652794
    http://www.bbc.co.uk
    fish soup
    http://www.slideshare.net/if-we-build-it-will-they-come-13652794
    https://youtu.fi/abcd1234_-z?list=ABC123XYZQQQ
    http://fishyoutu.be/XOiKXxDmDDQ
    https://wwwyoutube.com/v/XOiKXxDmDDQ
    http://www.boutube.com/watch?v=abcd1234_-z&feature=youtu.be
    http://elixir.be/abcd1234_-z&feature=channel
    http://www.youtube.biz/embed/abcd1234_-z?rel=0
    http://youtube.com/c/abcd1234_-z
    http://youtube.com.example.com/?vi=XOiKXxDmDDQ&feature=channel
    httpbla://youtube.com/?vi=XOiKXxDmDDQ&feature=channel
    ftp://youtube.com/?v=abcd1234_-z).freeze

    valid_youtube_urls.each do |url|
      cb.url = url
      assert renderer.can_render?, "Should be able to render: #{url}"
    end

    ([nil, ''] + invalid_youtube_urls).each do |url|
      cb.url = url
      refute renderer.can_render?, "Falsely claimed to render: #{url}"
    end

    url_sets = {
      'dLziBlI2qlo' => ['https://www.youtube.com/watch?v=dLziBlI2qlo',
                        'https://youtu.be/dLziBlI2qlo',
                        'https://www.youtube.com/embed/dLziBlI2qlo',
                        'https://www.youtube.com/v/dLziBlI2qlo',
                        'http://www.youtube.com/watch?v=dLziBlI2qlo&feature=youtu.be',
                        'https://youtube.com/watch?vi=dLziBlI2qlo&feature=channel',
                        'http://youtube.com/?feature=channel&v=dLziBlI2qlo',
                        'https://youtu.be/dLziBlI2qlo?list=ABC123XYZQQQ'],
      '7-N6Ij_5zpE' => ['https://www.youtube.com/watch?v=7-N6Ij_5zpE',
                        'https://youtu.be/7-N6Ij_5zpE',
                        'https://www.youtube.com/embed/7-N6Ij_5zpE',
                        'https://www.youtube.com/v/7-N6Ij_5zpE',
                        'http://www.youtube.com/ytscreeningroom?v=7-N6Ij_5zpE']
    }

    url_sets.each do |code, urls|
      urls.each do |url|
        stub_request(:head, url).to_timeout
        cb = FactoryBot.create(:content_blob, url: url)
        assert_equal "<iframe width=\"560\" height=\"315\" src=\"https://www.youtube-nocookie.com/embed/#{code}\" frameborder=\"0\" allowfullscreen></iframe>",
                     Seek::Renderers::YoutubeRenderer.new(cb).render
      end
    end

    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @git.add_remote_file('video.html', 'https://youtu.be/1234abcd')
    gb = @git.get_blob('video.html')
    renderer = Seek::Renderers::YoutubeRenderer.new(gb)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'


    renderer = Seek::Renderers::YoutubeRenderer.new(nil)
    assert_equal '', renderer.render
  end

  test 'pdf renderer' do
    blob = FactoryBot.create(:pdf_content_blob, asset: @asset)
    renderer = Seek::Renderers::PdfRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#outerContainer'

    @git.add_file('file.pdf', File.open(blob.filepath))
    git_blob = @git.get_blob('file.pdf')
    renderer = Seek::Renderers::PdfRenderer.new(git_blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#outerContainer'

    with_config_value(:pdf_conversion_enabled, true) do
      blob = FactoryBot.create(:docx_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      assert renderer.can_render?
    end

    with_config_value(:pdf_conversion_enabled, false) do
      blob = FactoryBot.create(:docx_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      refute renderer.can_render?
    end

    with_config_value(:pdf_conversion_enabled, true) do
      blob = FactoryBot.create(:image_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      refute renderer.can_render?
    end
  end

  test 'markdown renderer' do
    blob = FactoryBot.create(:markdown_content_blob, asset: @asset)
    renderer = Seek::Renderers::MarkdownRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select '.markdown-body h1', text: 'FAIRDOM-SEEK'

    @git.add_file('readme.md', File.open(blob.filepath))
    git_blob = @git.get_blob('readme.md')
    renderer = Seek::Renderers::MarkdownRenderer.new(git_blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select '.markdown-body h1', text: 'FAIRDOM-SEEK'

    blob = FactoryBot.create(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::MarkdownRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'jupyter notebook renderer' do
    blob = FactoryBot.create(:jupyter_notebook_content_blob, asset: @asset)
    renderer = Seek::Renderers::NotebookRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'body.jp-Notebook'
    assert_select 'div.jp-MarkdownOutput p', text: 'Import the libraries so that they can be used within the notebook'

    @git.add_file(blob.original_filename, File.open(blob.filepath))
    git_blob = @git.get_blob(blob.original_filename)
    renderer = Seek::Renderers::NotebookRenderer.new(git_blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'iframe'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'body.jp-Notebook'
    assert_select 'div.jp-MarkdownOutput p', text: 'Import the libraries so that they can be used within the notebook'

    blob = FactoryBot.create(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::NotebookRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'text renderer' do
    blob = FactoryBot.create(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::TextRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'pre', text: /This is a txt format/

    blob.rewind
    assert_equal "This is a txt format\n", renderer.render_standalone

    @git.add_file('test.txt', File.open(blob.filepath))
    git_blob = @git.get_blob('test.txt')
    renderer = Seek::Renderers::TextRenderer.new(git_blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'pre', text: /This is a txt format/

    git_blob.rewind
    assert_equal "This is a txt format\n", renderer.render_standalone

    @git.add_file('test.html', StringIO.new('<script>Danger!</script>'))
    git_blob = @git.get_blob('test.html')
    renderer = Seek::Renderers::TextRenderer.new(git_blob)
    assert renderer.can_render?
    assert_equal "<pre>&lt;script&gt;Danger!&lt;/script&gt;</pre>", renderer.render

    git_blob.rewind
    assert_equal "<script>Danger!</script>", renderer.render_standalone # Content-Security-Policy will prevent execution in standalone

    blob = FactoryBot.create(:csv_content_blob, asset: @asset)
    renderer = Seek::Renderers::TextRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'pre'

    blob = FactoryBot.create(:image_content_blob, asset: @asset)
    renderer = Seek::Renderers::TextRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'image renderer' do
    blob = FactoryBot.create(:image_content_blob, asset: @asset)
    renderer = Seek::Renderers::ImageRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'img.git-image-preview'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'img.git-image-preview'

    @git.add_file('test.png', File.open(blob.filepath))
    git_blob = @git.get_blob('test.png')
    renderer = Seek::Renderers::ImageRenderer.new(git_blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'img.git-image-preview'

    @html = Nokogiri::HTML.parse(renderer.render_standalone)
    assert_select 'iframe', count: 0
    assert_select '#navbar', count: 0
    assert_select 'img.git-image-preview'
    blob = FactoryBot.create(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::ImageRenderer.new(blob)
    refute renderer.can_render?
  end

  def document_root_element
    @html
  end
end

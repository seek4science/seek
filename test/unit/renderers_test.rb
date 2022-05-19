require 'test_helper'

class RenderersTest < ActiveSupport::TestCase
  include HtmlHelper
  include Rails::Dom::Testing::Assertions

  setup do
    @asset = Factory(:sop)
    @git = Factory(:git_version)
  end

  test 'factory' do
    cb = Factory(:content_blob)
    cb.url = 'http://bbc.co.uk'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::BlankRenderer, render.class

    cb.url = 'http://www.slideshare.net/mygrid/if-we-build-it-will-they-come-13652794'
    render = Seek::Renderers::RendererFactory.instance.renderer(cb)
    assert_equal Seek::Renderers::SlideshareRenderer, render.class

    factory = Seek::Renderers::RendererFactory.instance
    assert_equal Seek::Renderers::PdfRenderer, factory.renderer(Factory(:pdf_content_blob)).class
    assert_equal Seek::Renderers::PdfRenderer, factory.renderer(Factory(:docx_content_blob)).class
    assert_equal Seek::Renderers::MarkdownRenderer, factory.renderer(Factory(:markdown_content_blob)).class
    assert_equal Seek::Renderers::NotebookRenderer, factory.renderer(Factory(:jupyter_notebook_content_blob)).class
    assert_equal Seek::Renderers::TextRenderer, factory.renderer(Factory(:txt_content_blob)).class
    assert_equal Seek::Renderers::ImageRenderer, factory.renderer(Factory(:image_content_blob)).class
    assert_equal Seek::Renderers::BlankRenderer, factory.renderer(Factory(:binary_content_blob)).class
  end

  test 'blank renderer' do
    assert_equal '', Seek::Renderers::BlankRenderer.new(nil).render
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
    blob = Factory(:pdf_content_blob, asset: @asset)
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
      blob = Factory(:docx_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      assert renderer.can_render?
    end

    with_config_value(:pdf_conversion_enabled, false) do
      blob = Factory(:docx_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      refute renderer.can_render?
    end

    with_config_value(:pdf_conversion_enabled, true) do
      blob = Factory(:image_content_blob, asset: @asset)
      renderer = Seek::Renderers::PdfRenderer.new(blob)
      refute renderer.can_render?
    end
  end

  test 'markdown renderer' do
    blob = Factory(:markdown_content_blob, asset: @asset)
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

    blob = Factory(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::MarkdownRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'jupyter notebook renderer' do
    blob = Factory(:jupyter_notebook_content_blob, asset: @asset)
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

    blob = Factory(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::NotebookRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'text renderer' do
    blob = Factory(:txt_content_blob, asset: @asset)
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

    assert_equal "This is a txt format\n", renderer.render_standalone

    blob = Factory(:csv_content_blob, asset: @asset)
    renderer = Seek::Renderers::TextRenderer.new(blob)
    assert renderer.can_render?
    @html = Nokogiri::HTML.parse(renderer.render)
    assert_select 'pre'

    blob = Factory(:image_content_blob, asset: @asset)
    renderer = Seek::Renderers::TextRenderer.new(blob)
    refute renderer.can_render?
  end

  test 'image renderer' do
    blob = Factory(:image_content_blob, asset: @asset)
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
    blob = Factory(:txt_content_blob, asset: @asset)
    renderer = Seek::Renderers::ImageRenderer.new(blob)
    refute renderer.can_render?
  end

  def document_root_element
    @html
  end
end

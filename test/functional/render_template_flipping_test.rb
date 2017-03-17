require 'test_helper'

# tests specific to swapping templates using ActionView::Renderer.define_alternative with :seek_template
class RenderTemplateFlippingTest < ActionController::TestCase
  tests :homes

  test 'with biovel index rendering using syb' do
    with_alternative_rendering({ controller: :homes, seek_template: :index }, :index_biovel) do
      get :index
      assert_select 'div#home > div.carousel-wrapper', count: 1
    end
  end

  test 'with biovel index rendering using strings' do
    with_alternative_rendering({ controller: 'homes', seek_template: 'index' }, 'index_biovel') do
      get :index
      assert_select 'div#home > div.carousel-wrapper', count: 1
    end
  end

  test 'with biovel index rendering using mixed' do
    with_alternative_rendering({ controller: 'homes', seek_template: :index }, :index_biovel) do
      get :index
      assert_select 'div#home > div.carousel-wrapper', count: 1
    end
  end

  test 'with biovel index rendering using mixed2' do
    with_alternative_rendering({ controller: :homes, seek_template: 'index' }, :index_biovel) do
      get :index
      assert_select 'div#home > div.carousel-wrapper', count: 1
    end
  end
end

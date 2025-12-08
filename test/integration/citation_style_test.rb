require 'test_helper'

class CitationStyleTest < ActionDispatch::IntegrationTest
  def setup
    @model = FactoryBot.create(:model, policy: FactoryBot.create(:public_policy))
    @doi = '10.1.1.1/xxx'
    @model.latest_version.update_attribute(:doi, @doi)
    @current_user = @model.contributor.user
    post '/session', params: { login: @model.contributor.user.login, password: generate_user_password }
  end

  test 'remembers user-selected citation' do
    doi_citation_mock

    get model_path(@model)
    # APA by default
    assert_select '#citation' do
      assert_select 'div[data-citation-style=?]', Seek::Config.default_citation_style, text: /Bacall, F/, count: 1
    end
    assert_select '#citation-style-select' do
      assert_select "option[selected='selected'][value=?]", Seek::Config.default_citation_style
    end

    new_style = 'journal-of-infectious-diseases'

    get citation_path(@doi, style: new_style, format: :js), xhr: true

    get model_path(@model)
    assert_select '#citation' do
      assert_select 'div[data-citation-style=?]', Seek::Config.default_citation_style, count: 0
      assert_select 'div[data-citation-style=?]', new_style, text: /Bacall F/, count: 1
    end
    assert_select '#citation-style-select' do
      assert_select "option[selected='selected'][value=?]", new_style
    end
  end

  test 'handles invalid style selection' do
    doi_citation_mock

    get citation_path(@doi, style: 'fjkgdfhgkjdf123', format: :js), xhr: true

    assert_includes response.body, 'Invalid citation style'
  end

  test 'handles CSL fetch error' do
    stub_request(:get, /(https?:\/\/)?(dx\.)?doi\.org\/.+/)
      .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
      .to_return(body: 'Error!', status: 500)

    get citation_path(@doi, style: 'apa', format: :js), xhr: true

    assert_includes response.body, 'An error occurred whilst fetching the citation'
  end

  private

  def doi_citation_mock
    stub_request(:get, /(https?:\/\/)?(dx\.)?doi\.org\/.+/)
        .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
        .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)
  end
end

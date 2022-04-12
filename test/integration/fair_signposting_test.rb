require 'test_helper'

class FairSignpostingTest < ActionDispatch::IntegrationTest
  include MockHelper

  test 'fair signposting for data file' do
    df = Factory(:data_file)
    login_as(df.contributor.user)

    get data_file_path(df)

    assert_response :success
    links = parse_link_header
    assert_equal 3, links.size
    assert_link(links, data_file_url(df, version: 1), rel: 'describedby', type: :datacite_xml)
    assert_link(links, data_file_url(df, version: 1), rel: 'describedby', type: :jsonld)
    assert_link(links, download_data_file_url(df, version: 1), rel: 'item', type: :pdf)
  end

  test 'fair signposting for data file with doi' do
    doi_citation_mock
    df = Factory(:data_file)
    dfv = Factory(:data_file_version_with_blob, content_blob: Factory(:image_content_blob), data_file: df, doi: '10.5075/abcd')
    login_as(df.contributor.user)

    get data_file_path(df, version: 2)

    assert_response :success
    links = parse_link_header
    assert_equal 4, links.size
    assert_link(links, data_file_url(df, version: 2), rel: 'describedby', type: :datacite_xml)
    assert_link(links, data_file_url(df, version: 2), rel: 'describedby', type: :jsonld)
    assert_link(links, 'https://doi.org/10.5075/abcd', rel: 'cite-as')
    assert_link(links, download_data_file_url(df, version: 2), rel: 'item', type: :png)
  end

  test 'fair signposting for workflow' do
    wf = Factory(:workflow)
    login_as(wf.contributor.user)

    get workflow_path(wf)

    assert_response :success
    links = parse_link_header
    assert_equal 3, links.size
    assert_link(links, workflow_url(wf, version: 1), rel: 'describedby', type: :datacite_xml)
    assert_link(links, workflow_url(wf, version: 1), rel: 'describedby', type: :jsonld)
    assert_link(links, ro_crate_workflow_url(wf, version: 1), rel: 'item', type: :zip)
  end

  test 'fair signposting for publication' do
    doi_citation_mock
    pub = Factory(:min_publication)

    get publication_path(pub)

    assert_response :success
    links = parse_link_header
    assert_equal 1, links.size
    assert_link(links, 'https://doi.org/10.5075/abcd', rel: 'cite-as')
  end

  test 'fair signposting for model' do
    doi_citation_mock
    mod = Factory(:model_2_files)
    login_as(mod.contributor.user)

    get model_path(mod)

    assert_response :success
    links = parse_link_header
    assert_equal 2, links.size
    assert_link(links, model_url(mod, version: 1), rel: 'describedby', type: :datacite_xml)
    assert_link(links, download_model_url(mod, version: 1), rel: 'item', type: :zip)
  end

  test 'fair signposting for sop' do
    sop = Factory(:sop)
    login_as(sop.contributor.user)

    get sop_path(sop)

    assert_response :success
    links = parse_link_header
    assert_equal 2, links.size
    assert_link(links, sop_url(sop, version: 1), rel: 'describedby', type: :datacite_xml)
    assert_link(links, download_sop_url(sop, version: 1), rel: 'item', type: :pdf)
  end

  test 'fair signposting for assay' do
    doi_citation_mock
    a = Factory(:assay)
    login_as(a.contributor.user)

    get assay_path(a)

    assert_response :success
    assert_nil response.headers['Link'], 'Should not have any signposting links'
  end

  private

  def assert_link(links, url, props = {})
    assert links.any? { |u, p| u == url && props.all? { |k, v| p[k] == props[k] } }, "Expected links to contain: #{url} and #{props}"
  end

  def parse_link_header
    if response.headers['Link']
      response.headers['Link'].split(',').map(&:strip).map do |link|
        segments = link.split(';').map(&:strip)
        url = segments[0].match(/<(.+)>/)
        if url
          props = {}
          segments[1..-1].each do |seg|
            k, v = seg.split('=').map(&:strip)
            str = v.match(/"(.+)"/)
            v = str[1] if str
            v = Mime::Type.lookup(v).to_sym if k == 'type'
            props[k.to_sym] = v
          end
          [url[1], props]
        end
      end.compact
    end
  end

  def doi_citation_mock
    stub_request(:get, /(https?:\/\/)?(dx\.)?doi\.org\/.+/)
      .with(headers: { 'Accept' => 'application/vnd.citationstyles.csl+json' })
      .to_return(body: File.new("#{Rails.root}/test/fixtures/files/mocking/doi_metadata.json"), status: 200)
  end

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end

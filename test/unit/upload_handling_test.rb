require 'test_helper'

require 'seek/upload_handling/data_upload'
require 'seek/upload_handling/examine_url'

class UploadHandingTest < ActiveSupport::TestCase

  include Seek::UploadHandling::DataUpload
  include Seek::UploadHandling::DataUpload
  include Seek::UrlValidation

  test 'valid scheme?' do
    assert_equal %w(file).sort, Seek::UploadHandling::ContentInspection::INVALID_SCHEMES.sort
    assert valid_scheme?('http://bbc.co.uk')
    assert valid_scheme?('https://bbc.co.uk')
    assert valid_scheme?('ftp://bbc.co.uk')
    assert valid_scheme?('ssh://bbc.co.uk')
    refute valid_scheme?('file:///secret/documents.txt')
  end

  test 'content_blob_params' do
    @params = ActionController::Parameters.new({ content_blobs: [{ fish: 1, soup: 2 }],
                                                 data_file: { title: 'george' } })
    assert_equal 1, content_blobs_params.length
    assert_equal 1, content_blobs_params.first[:fish]
    assert_equal 2, content_blobs_params.first[:soup]
  end

  test 'default to http if missing' do
    params = { data_url: 'fish.com/path?query=yes' }
    default_to_http_if_missing(params)
    assert_equal('http://fish.com/path?query=yes', params[:data_url])

    params[:data_url] = 'https://fish.com/path?query=yes'
    default_to_http_if_missing(params)
    assert_equal('https://fish.com/path?query=yes', params[:data_url])

    params[:data_url] = nil
    default_to_http_if_missing(params)
    assert_nil(params[:data_url])

    params[:data_url] = 'sdfhksdlfsdkfh'
    default_to_http_if_missing(params)
    assert_equal('sdfhksdlfsdkfh', params[:data_url])
  end

  test 'asset params' do
    @params = ActionController::Parameters.new({ content_blob: { fish: 1, soup: 2 },
                                                 data_file: { title: 'george' },
                                                 sop: { title: 'mary' } })
    assert_equal 'george', asset_params[:title]
    assert_equal 1, asset_params.keys.length
    @controller_name = 'sops'
    assert_equal 'mary', asset_params[:title]
    assert_equal 1, asset_params.keys.length
  end

  test 'check url response code' do
    stub_request(:head, 'http://bbc.co.uk/').to_return(status: 200, body: '', headers: { content_type: 'text/html', content_length: '555' })
    stub_request(:head, 'http://not-there.com').to_return(status: 404, body: '', headers: {})
    stub_request(:head, 'http://server-error.com').to_return(status: 500, body: '', headers: {})
    stub_request(:head, 'http://forbidden.com').to_return(status: 403, body: '', headers: {})
    stub_request(:head, 'http://unauthorized.com').to_return(status: 401, body: '', headers: {})
    stub_request(:head, 'http://methodnotallowed.com').to_return(status: 405, body: '', headers: {})

    assert_equal 200, check_url_response_code('http://bbc.co.uk')
    assert_equal 404, check_url_response_code('http://not-there.com')
    assert_equal 500, check_url_response_code('http://server-error.com')
    assert_equal 403, check_url_response_code('http://forbidden.com')
    assert_equal 401, check_url_response_code('http://unauthorized.com')
    assert_equal 405, check_url_response_code('http://methodnotallowed.com')

    # redirection will be followed
    stub_request(:head, 'http://moved.com').to_return(status: 301, body: '', headers: { location: 'http://bbc.co.uk' })
    stub_request(:head, 'http://moved2.com').to_return(status: 302, body: '', headers: { location: 'http://forbidden.com' })
    assert_equal 200, check_url_response_code('http://moved.com')
    assert_equal 403, check_url_response_code('http://moved2.com')
  end

  test 'fetch url headers' do
    stub_request(:head, 'http://bbc.co.uk/').to_return(status: 200,
                                                       body: '',
                                                       headers: { content_type: 'text/html', content_length: '555' })
    headers = fetch_url_headers('http://bbc.co.uk')
    assert_equal 'text/html', headers[:content_type]
    assert_equal 555, headers[:file_size]

    stub_request(:head, 'http://somewhere.org/excel.xls').to_return(status: 200,
                                                                    body: '',
                                                                    headers: { content_type: 'application/vnd.ms-excel', content_length: '1111' })
    headers = fetch_url_headers('http://somewhere.org/excel.xls')
    assert_equal 'application/vnd.ms-excel', headers[:content_type]
    assert_equal 1111, headers[:file_size]

    stub_request(:head, 'http://not-there.com').to_return(status: 404, body: '', headers: {})
    stub_request(:get, 'http://not-there.com').to_return(status: 404, body: '', headers: {})

    assert_equal 404, fetch_url_headers('http://not-there.com')[:code]

    # follows redirection
    stub_request(:head, 'http://moved.com').to_return(status: 301, body: '', headers: { location: 'http://bbc.co.uk' })
    headers = fetch_url_headers('http://moved.com')
    assert_equal 'text/html', headers[:content_type]
    assert_equal 555, headers[:file_size]
  end

  test 'content type from filename' do
    assert_equal 'text/html', content_type_from_filename(nil)
    # FIXME: , MERGENOTE - .xml gives an incorrect mime type of sbml+xml due to the ordering
    checks = [
      { f: 'test.jpg', t: 'image/jpeg' },
      { f: 'test.JPG', t: 'image/jpeg' },
      { f: 'test.png', t: 'image/png' },
      { f: 'test.PNG', t: 'image/png' },
      { f: 'test.jpeg', t: 'image/jpeg' },
      { f: 'test.JPEG', t: 'image/jpeg' },
      { f: 'test.xls', t: 'application/excel' },
      { f: 'test.doc', t: 'application/msword' },
      { f: 'test.xlsx', t: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' },
      { f: 'test.docx', t: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' },
      { f: 'test.XLs', t: 'application/excel' },
      { f: 'test.Doc', t: 'application/msword' },
      { f: 'test.XLSX', t: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' },
      { f: 'test.dOCx', t: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' },
      { f: 'unknown.xxx', t: 'application/octet-stream' },
      { f: nil, t: 'text/html' }
    ]
    checks.each do |check|
      assert_equal check[:t], content_type_from_filename(check[:f]), "Expected #{check[:t]} for #{check[:f]}"
    end
  end

  test 'content is webpage?' do
    assert content_is_webpage?('text/html')
    assert content_is_webpage?('text/html; charset=UTF-8')
    refute content_is_webpage?('application/zip')
    refute content_is_webpage?(nil)
  end

  test 'valid url?' do
    assert valid_url?('http://fish.com')
    assert valid_url?('https://fish.com')
    assert valid_url?('http://fish.com/fish.txt')
    assert valid_url?('ftp://fish.com/fish.txt')
    assert valid_url?('mailto:fish@fishmail.fish')
    assert valid_url?('skype:fish.user')

    refute valid_url?('urn:fish:fish.com/fish.txt')
    refute valid_url?('http://fish.com   ')
    refute valid_url?('http://fish.com/fish.txt    ')
    refute valid_url?('x dd s')
    refute valid_url?('sdfsdf')
    refute valid_url?('/somewhere/fish.txt')
    refute valid_url?(nil)
  end

  test 'determine_filename_from_disposition' do
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename="_form.html.erb"')
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename=_form.html.erb')
    assert_equal '_form.html.erb', determine_filename_from_disposition('attachment;    filename="_form.html.erb"')
    assert_nil determine_filename_from_disposition(nil)
    assert_nil determine_filename_from_disposition('')
  end

  test 'determine filename from url' do
    assert_equal 'fred.txt', determine_filename_from_url('http://place.com/fred.txt')
    assert_equal 'fred.txt', determine_filename_from_url('http://place.com/fred.txt   ')
    assert_equal 'jenny.txt', determine_filename_from_url('http://place.com/here/he%20/jenny.txt')
    assert_nil determine_filename_from_url('http://place.com')
    assert_nil determine_filename_from_url('http://place.com/')
    assert_nil determine_filename_from_url('')
    assert_nil determine_filename_from_url('sdfsdf')
    assert_nil determine_filename_from_url(nil)
  end

  test 'check for data or url' do
    refute check_for_data_or_url(data: '', data_url: '')
    assert check_for_data_or_url(data: 'hhhh')
    assert check_for_data_or_url(data_url: 'hhhh')

    refute check_for_data_or_url(data: [], data_url: [])
    assert check_for_data_or_url(data: ['hhhh'])
    assert check_for_data_or_url(data_url: ['hhhh'])
  end

  test 'retained content blob ids' do
    @params = { retained_content_blob_ids: [1, 2] }
    assert_equal [1, 2], retained_content_blob_ids
    @params = {}
    assert_equal [], retained_content_blob_ids
    @params = { content_blobs: nil }
    assert_equal [], retained_content_blob_ids
    @params = { retained_content_blob_ids: [1, 2, 3] }
    assert_equal [1, 2, 3], retained_content_blob_ids
  end

  test 'model image present?' do
    file_with_content = fixture_file_upload('files/file', 'text/plain')

    @params = { model_image: { image_file: file_with_content }, content_blob: {}, model: { title: 'fish' } }
    assert model_image_present?
    @params = { model_image: {}, content_blob: {}, model: { title: 'fish' } }
    refute model_image_present?
    @params = { content_blob: {}, model: { title: 'fish' } }
    refute model_image_present?
  end

  test 'check for data if present' do
    file_with_content = fixture_file_upload('files/file', 'text/plain')
    empty_content = fixture_file_upload('files/empty_file', 'text/plain')

    assert check_for_empty_data_if_present(data: '', data_url: 'http://fish')
    assert check_for_empty_data_if_present(data: file_with_content, data_url: '')
    assert check_for_empty_data_if_present(data: file_with_content, data_url: [])
    refute check_for_empty_data_if_present(data: empty_content, data_url: '')
    refute check_for_empty_data_if_present(data: empty_content, data_url: [])
    refute check_for_empty_data_if_present(data: empty_content)

    assert check_for_empty_data_if_present(data: [], data_url: 'http://fish')
    assert check_for_empty_data_if_present(data: [file_with_content], data_url: '')
    assert check_for_empty_data_if_present(data: [file_with_content], data_url: [])
    refute check_for_empty_data_if_present(data: [empty_content], data_url: '')
    refute check_for_empty_data_if_present(data: [empty_content], data_url: [])
    refute check_for_empty_data_if_present(data: [empty_content])
    refute check_for_empty_data_if_present(data: [empty_content, file_with_content])
  end

  # allows some methods to be tested the rely on flash.now[:error]
  def flash
    ActionDispatch::Flash::FlashHash.new
  end

  # mock out the params method, set @params for the desired params for the test
  attr_reader :params

  # mocks out the controller name, defaults to data_files, but can be changed by setting @controller_name
  def controller_name
    @controller_name || 'data_files'
  end

  private

  def fetch_url_headers(url)
    Seek::DownloadHandling::HTTPHandler.new(url).info
  end

  def check_url_response_code(url)
    Seek::DownloadHandling::HTTPHandler.new(url, fallback_to_get: false).info[:code]
  end
end

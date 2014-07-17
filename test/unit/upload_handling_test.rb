require 'test_helper'

class UploadHandingTest < ActiveSupport::TestCase
  include Seek::UploadHandling

  test 'valid scheme?' do
    assert_equal %w(http https ftp).sort, Seek::UploadHandling::VALID_SCHEMES.sort
    assert valid_scheme?('http://bbc.co.uk')
    assert valid_scheme?('https://bbc.co.uk')
    assert valid_scheme?('ftp://bbc.co.uk')
    refute valid_scheme?('ssh://bbc.co.uk')

    # also without a normal url
    refute valid_scheme?('bob')
    refute valid_scheme?('')
    refute valid_scheme?(nil)
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
    assert_equal '555', headers[:content_length]

    stub_request(:head, 'http://somewhere.org/excel.xls').to_return(status: 200,
                                                                    body: '',
                                                                    headers: { content_type: 'application/vnd.ms-excel', content_length: '1111' })
    headers = fetch_url_headers('http://somewhere.org/excel.xls')
    assert_equal 'application/vnd.ms-excel', headers[:content_type]
    assert_equal '1111', headers[:content_length]

    stub_request(:head, 'http://not-there.com').to_return(status: 404, body: '', headers: {})
    assert_raise RestClient::ResourceNotFound do
      fetch_url_headers('http://not-there.com')
    end

    # follows redirection
    stub_request(:head, 'http://moved.com').to_return(status: 301, body: '', headers: { location: 'http://bbc.co.uk' })
    headers = fetch_url_headers('http://moved.com')
    assert_equal 'text/html', headers[:content_type]
    assert_equal '555', headers[:content_length]

  end

  test 'content is webpage?' do
    assert content_is_webpage?('text/html')
    assert content_is_webpage?('text/html; charset=UTF-8')
    refute content_is_webpage?('application/zip')
    refute content_is_webpage?(nil)
  end

  test 'valid uri?' do
    assert valid_uri?('http://fish.com')
    assert valid_uri?('http://fish.com')
    refute valid_uri?('x dd s')
  end

  test 'determine_filename_from_disposition' do
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename="_form.html.erb"')
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename=_form.html.erb')
    assert_equal '_form.html.erb', determine_filename_from_disposition('attachment;    filename="_form.html.erb"')
    assert_nil determine_filename_from_disposition(nil)
    assert_nil determine_filename_from_disposition('')
  end
end

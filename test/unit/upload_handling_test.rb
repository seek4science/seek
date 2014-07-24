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

  test 'update params for batch' do
    p = {:data=>"some data",:data_url=>"some url",:original_filename=>"file.txt"}
    #not batch so shouldn't be affected
    expected = {:data=>"some data",:data_url=>"some url",:original_filename=>"file.txt"}
    assert_equal expected,update_params_for_batch(p)

    p = {:data_0=>"a",:data_1=>"b",:data_2=>"c"}
    expected = {:data=>["a","b","c"]}
    assert_equal expected,update_params_for_batch(p)

    #order preserved
    p = {:data_3=>"d",:data_0=>"a",:data_2=>"c",:data_1=>"b"}
    expected = {:data=>["a","b","c","d"]}
    assert_equal expected,update_params_for_batch(p)

    p = {:data_url_3=>"d",:data_url_0=>"a",:data_url_2=>"c",:data_url_1=>"b"}
    expected = {:data_url=>["a","b","c","d"]}
    assert_equal expected,update_params_for_batch(p)

    #strip blank
    p = {:data_url_3=>"d",:data_url_0=>"",:data_url_2=>"c",:data_url_1=>"b"}
    expected = {:data_url=>["b","c","d"]}
    assert_equal expected,update_params_for_batch(p)
  end

  test "arrayify params" do
    file_with_content = ActionDispatch::Http::UploadedFile.new({
                                                                   :filename => 'file',
                                                                   :content_type => 'text/plain',
                                                                   :tempfile => StringIO.new("fish")
                                                               })
    p = {:data_url=>["b","c","d"],:original_filename=>["1","2","3"], :make_local_copy=>["1","0","1"]}
    expected = [{:data_url=>"b",:original_filename=>"1",:make_local_copy=>"1"},
                {:data_url=>"c",:original_filename=>"2",:make_local_copy=>"0"},
                {:data_url=>"d",:original_filename=>"3",:make_local_copy=>"1"}]
    assert_equal expected,arrayify_params(p)

    p = {:data_url=>"some url",:original_filename=>"file.txt", :make_local_copy=>"1"}
    expected = [{:data_url=>"some url",:original_filename=>"file.txt",:make_local_copy=>"1"}]
    assert_equal expected,arrayify_params(p)

    p = {:data=>file_with_content}
    expected = [{:data=>file_with_content}]
    assert_equal expected,arrayify_params(p)

    p = {:data=>[file_with_content,file_with_content]}
    expected = [{:data=>file_with_content},:data=>file_with_content]
    assert_equal expected,arrayify_params(p)

    p = {:data_url=>["b","c"],:original_filename=>["1","2"],:data=>[file_with_content],:make_local_copy=>["0","1"]}
    expected = [{:data_url=>"b",:original_filename=>"1",:make_local_copy=>"0"},{:data_url=>"c",:original_filename=>"2",:make_local_copy=>"1"},{:data=>file_with_content}]
    assert_equal expected,arrayify_params(p)

    #remvoves blank urls or data
    p = {:data_url=>"",:data=>file_with_content}
    expected = [{:data=>file_with_content}]
    assert_equal expected,arrayify_params(p)

    p = {:data_url=>"http://fish.com",:original_filename=>"dd",:make_local_copy=>"1",:data=>""}
    expected = [{:data_url=>"http://fish.com",:original_filename=>"dd",:make_local_copy=>"1"}]
    assert_equal expected,arrayify_params(p)
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
    assert valid_uri?('http://fish.com   ')
    assert valid_uri?('http://fish.com/fish.txt')
    assert valid_uri?('http://fish.com/fish.txt    ')
    refute valid_uri?('x dd s')
    refute valid_uri?(nil)
  end

  test 'determine_filename_from_disposition' do
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename="_form.html.erb"')
    assert_equal '_form.html.erb', determine_filename_from_disposition('inline; filename=_form.html.erb')
    assert_equal '_form.html.erb', determine_filename_from_disposition('attachment;    filename="_form.html.erb"')
    assert_nil determine_filename_from_disposition(nil)
    assert_nil determine_filename_from_disposition('')
  end

  test "determine filename from url" do
    assert_equal 'fred.txt',determine_filename_from_url("http://place.com/fred.txt")
    assert_equal 'fred.txt',determine_filename_from_url("http://place.com/fred.txt   ")
    assert_equal 'jenny.txt',determine_filename_from_url("http://place.com/here/he%20/jenny.txt")
    assert_nil determine_filename_from_url('http://place.com')
    assert_nil determine_filename_from_url('http://place.com/')
    assert_nil determine_filename_from_url('')
    assert_nil determine_filename_from_url('sdfsdf')
    assert_nil determine_filename_from_url(nil)
  end

  test "validate params" do

    refute validate_params({:data=>"",:data_url=>""})
    assert validate_params({:data=>"hhhh"})
    assert validate_params({:data_url=>"hhhh"})

    refute validate_params({:data=>[],:data_url=>[]})
    assert validate_params({:data=>["hhhh"]})
    assert validate_params({:data_url=>["hhhh"]})

  end

  test "check for data if present" do
    file_with_content = ActionDispatch::Http::UploadedFile.new({
                                                                   :filename => 'file',
                                                                   :content_type => 'text/plain',
                                                                   :tempfile => StringIO.new("fish")
                                                               })
    empty_content = ActionDispatch::Http::UploadedFile.new({
                                                               :filename => 'file',
                                                               :content_type => 'text/plain',
                                                               :tempfile => StringIO.new("")
                                                           })
    assert check_for_empty_data_if_present({:data=>"",:data_url=>"http://fish"})
    assert check_for_empty_data_if_present({:data=>file_with_content,:data_url=>""})
    assert check_for_empty_data_if_present({:data=>file_with_content,:data_url=>[]})
    refute check_for_empty_data_if_present({:data=>empty_content,:data_url=>""})
    refute check_for_empty_data_if_present({:data=>empty_content,:data_url=>[]})
    refute check_for_empty_data_if_present({:data=>empty_content})

    assert check_for_empty_data_if_present({:data=>[],:data_url=>"http://fish"})
    assert check_for_empty_data_if_present({:data=>[file_with_content],:data_url=>""})
    assert check_for_empty_data_if_present({:data=>[file_with_content],:data_url=>[]})
    refute check_for_empty_data_if_present({:data=>[empty_content],:data_url=>""})
    refute check_for_empty_data_if_present({:data=>[empty_content],:data_url=>[]})
    refute check_for_empty_data_if_present({:data=>[empty_content]})
    refute check_for_empty_data_if_present({:data=>[empty_content,file_with_content]})



  end

  #allows some methods to be tested the rely on flash.now[:error]
  def flash
    ActionDispatch::Flash::FlashHash.new
  end
end

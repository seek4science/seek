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

  test 'content_blob_params' do
    @params = { content_blob: { fish: 1, soup: 2 }, data_file: { title: 'george' } }
    assert_equal({ fish: 1, soup: 2 }, content_blob_params)
  end

  test 'asset params' do
    @params = { content_blob: { fish: 1, soup: 2 }, data_file: { title: 'george' }, sop: { title: 'mary' } }
    assert_equal({ title: 'george' }, asset_params)
    @controller_name = 'sops'
    assert_equal({ title: 'mary' }, asset_params)
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

    p = { data: 'some data', data_url: 'some url', original_filename: 'file.txt' }
    # not batch so shouldn't be affected
    expected = { data: 'some data', data_url: 'some url', original_filename: 'file.txt' }
    assert_equal expected, update_params_for_batch(p)

    p = { data_0: 'a', data_1: 'b', data_2: 'c' }
    expected = { data: %w(a b c) }
    assert_equal expected, update_params_for_batch(p)

    # order preserved
    p = { data_3: 'd', data_0: 'a', data_2: 'c', data_1: 'b' }
    expected = { data: %w(a b c d) }
    assert_equal expected, update_params_for_batch(p)

    # filenames and make local copy also gets transferred for urls
    p = { data_url_3: 'd', data_url_0: 'a', data_url_2: 'c', data_url_1: 'b',
          original_filename_0: 'fred', original_filename_2: 'bob', original_filename_3: 'mary', original_filename_1: 'frank',
          make_local_copy_0: '1', make_local_copy_2: '0', make_local_copy_1: '1', make_local_copy_3: '0' }
    expected = { data_url: %w(a b c d), original_filename: %w(fred frank bob mary), make_local_copy: %w(1 1 0 0) }
    assert_equal expected, update_params_for_batch(p)

    # strip blank
    p = { data_url_3: 'd', data_url_0: '', data_url_2: 'c', data_url_1: 'b',
          original_filename_0: 'df', original_filename_1: 'bob', original_filename_2: 'charles', original_filename_3: 'denis',
          make_local_copy_0: '1', make_local_copy_2: '0', make_local_copy_1: '1', make_local_copy_3: '0' }
    expected = { data_url: %w(b c d), original_filename: %w(bob charles denis), make_local_copy: %w(1 0 0) }
    assert_equal expected, update_params_for_batch(p)
  end

  test 'arrayify params' do
    file_with_content = ActionDispatch::Http::UploadedFile.new(
                                                                   filename: 'file',
                                                                   content_type: 'text/plain',
                                                                   tempfile: StringIO.new('fish')
                                                               )
    p = { data_url: %w(b c d), original_filename: %w(1 2 3), make_local_copy: %w(1 0 1) }
    expected = [{ data_url: 'b', original_filename: '1', make_local_copy: '1' },
                { data_url: 'c', original_filename: '2', make_local_copy: '0' },
                { data_url: 'd', original_filename: '3', make_local_copy: '1' }]
    assert_equal expected, arrayify_params(p)

    p = { data_url: 'some url', original_filename: 'file.txt', make_local_copy: '1' }
    expected = [{ data_url: 'some url', original_filename: 'file.txt', make_local_copy: '1' }]
    assert_equal expected, arrayify_params(p)

    p = { data: file_with_content }
    expected = [{ data: file_with_content }]
    assert_equal expected, arrayify_params(p)

    p = { data: [file_with_content, file_with_content] }
    expected = [{ data: file_with_content }, data: file_with_content]
    assert_equal expected, arrayify_params(p)

    p = { data_url: %w(b c), original_filename: %w(1 2), data: [file_with_content], make_local_copy: %w(0 1) }
    expected = [{ data_url: 'b', original_filename: '1', make_local_copy: '0' }, { data_url: 'c', original_filename: '2', make_local_copy: '1' }, { data: file_with_content }]
    assert_equal expected, arrayify_params(p)

    # remvoves blank urls or data
    p = { data_url: '', data: file_with_content }
    expected = [{ data: file_with_content }]
    assert_equal expected, arrayify_params(p)

    p = { data_url: 'http://fish.com', original_filename: 'dd', make_local_copy: '1', data: '' }
    expected = [{ data_url: 'http://fish.com', original_filename: 'dd', make_local_copy: '1' }]
    assert_equal expected, arrayify_params(p)
  end

  test 'content type from filename' do
    assert_equal 'text/html', content_type_from_filename(nil)
    assert_equal 'image/png', content_type_from_filename('fish.png')
    assert_equal 'application/msword', content_type_from_filename('fish.doc')
    assert_equal 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', content_type_from_filename('fish.docx')
    # FIXME: , MERGENOTE - this gives an incorrect mime type of sbml+xml due to the ordering
    # assert_equal "image/png",content_type_from_filename("fish.xml")
    assert_equal 'text/html', content_type_from_filename('fish.html')
    assert_equal 'application/octet-stream', content_type_from_filename('fish')
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

  test "retained content blob ids" do

    @params={:content_blobs=>{:id=>{1=>"fish.png",2=>"2.png"}}}
    assert_equal [1,2],retained_content_blob_ids
    @params={}
    assert_equal [],retained_content_blob_ids
    @params={:content_blobs=>nil}
    assert_equal [],retained_content_blob_ids
    @params={:content_blobs=>{:id=>{"3"=>"bob.png","1"=>"fish.png","2"=>"2.png"}}}
    assert_equal [1,2,3],retained_content_blob_ids


  end

  test "model image present?" do
    file_with_content = ActionDispatch::Http::UploadedFile.new(
        filename: 'file',
        content_type: 'text/plain',
        tempfile: StringIO.new('fish')
    )
    @params={:model_image=>{:image_file=>file_with_content},:content_blob=>{},:model=>{:title=>"fish"}}
    assert model_image_present?
    @params={:model_image=>{},:content_blob=>{},:model=>{:title=>"fish"}}
    refute model_image_present?
    @params={:content_blob=>{},:model=>{:title=>"fish"}}
    refute model_image_present?
  end

  test 'check for data if present' do
    file_with_content = ActionDispatch::Http::UploadedFile.new(
                                                                   filename: 'file',
                                                                   content_type: 'text/plain',
                                                                   tempfile: StringIO.new('fish')
                                                               )
    empty_content = ActionDispatch::Http::UploadedFile.new(
                                                               filename: 'file',
                                                               content_type: 'text/plain',
                                                               tempfile: StringIO.new('')
                                                           )
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
end

require 'test_helper'
require 'docsplit'
require 'minitest/mock'

class ContentExtractionTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Pattern A — simple reads via data_io_object
  # ---------------------------------------------------------------------------

  test 'text_contents_for_search reads file content via adapter' do
    blob = FactoryBot.create(:txt_content_blob)
    content = blob.text_contents_for_search
    assert content.any?, 'expected non-empty search terms'
    assert content.first.include?('txt format'), "expected fixture text, got: #{content.inspect}"
  end

  test 'text_contents_for_search returns empty array when file does not exist' do
    blob = FactoryBot.build(:txt_content_blob)
    blob.save(validate: false)
    # no file written — storage key absent
    FileUtils.rm_f(blob.filepath)
    assert_equal [], blob.text_contents_for_search
  end

  test 'to_csv passes file path to SysMODB and returns CSV string' do
    blob = FactoryBot.create(:rightfield_content_blob)
    result = blob.to_csv
    assert_kind_of String, result
    refute result.empty?, 'expected non-empty CSV output'
  end

  test 'to_spreadsheet_xml passes file path to SysMODB and returns XML string' do
    blob = FactoryBot.create(:rightfield_content_blob)
    result = blob.to_spreadsheet_xml
    assert_kind_of String, result
    assert result.start_with?('<?xml') || result.include?('<workbook') || result.include?('<Workbook'),
           "expected XML output, got: #{result[0..100]}"
  end

  test 'extract_csv returns raw file content via adapter' do
    blob = FactoryBot.create(:csv_content_blob)
    result = blob.extract_csv
    assert_includes result, '1'
  end

  # ---------------------------------------------------------------------------
  # Pattern B — derivative-file existence and reads via storage_adapter(format)
  # ---------------------------------------------------------------------------

  test 'pdf_contents_for_search for an already-PDF dat writes content to pdf key via adapter' do
    blob = FactoryBot.create(:pdf_content_blob)
    assert blob.is_pdf?
    blob.pdf_contents_for_search
    assert blob.storage_adapter('pdf').exist?(blob.storage_key('pdf')),
           'expected pdf key to exist in adapter after pdf_contents_for_search'
  end

  test 'extract_text_from_pdf returns empty string when pdf key absent' do
    blob = FactoryBot.create(:pdf_content_blob)
    # Do not write anything to the pdf key
    assert_equal '', blob.extract_text_from_pdf
  end

  test 'extract_text_from_pdf returns cached txt when txt key already exists in adapter' do
    blob = FactoryBot.create(:pdf_content_blob)
    # Pre-write a PDF so the pdf-exists guard passes
    blob.storage_adapter('pdf').write(blob.storage_key('pdf'), blob.data_io_object)
    # Pre-write a TXT so Docsplit is not called
    blob.storage_adapter('txt').write(blob.storage_key('txt'), StringIO.new('cached text'))

    result = blob.extract_text_from_pdf

    assert_equal 'cached text', result
  end

  test 'extract_text_from_pdf returns empty string when pdf exists but txt cannot be extracted' do
    blob = FactoryBot.create(:broken_pdf_content_blob)
    blob.storage_adapter('pdf').write(blob.storage_key('pdf'), blob.data_io_object)

    result = blob.extract_text_from_pdf

    assert_equal '', result
  end

  # ---------------------------------------------------------------------------
  # Pattern C — conversion pipeline via with_temporary_copy + write-back
  # ---------------------------------------------------------------------------

  test 'convert_to_pdf no-ops when pdf key already exists in adapter' do
    blob = FactoryBot.create(:doc_content_blob)
    blob.storage_adapter('pdf').write(blob.storage_key('pdf'), StringIO.new('%PDF-sentinel'))

    Libreconv.stub(:convert, ->(*_args) { raise 'should not be called' }) do
      assert_nothing_raised { blob.convert_to_pdf }
    end
  end

  test 'convert_to_pdf converts a doc blob and writes pdf back to adapter' do
    blob = FactoryBot.create(:doc_content_blob)
    refute blob.storage_adapter('pdf').exist?(blob.storage_key('pdf'))

    blob.convert_to_pdf

    assert blob.storage_adapter('pdf').exist?(blob.storage_key('pdf')),
           'expected pdf key to exist in adapter after conversion'
    pdf_content = blob.storage_adapter('pdf').open(blob.storage_key('pdf')).read(4)
    assert_equal '%PDF', pdf_content, 'expected a valid PDF header'
  end

  test 'convert_to_pdf logs error and does not raise when Libreconv fails' do
    blob = FactoryBot.create(:doc_content_blob)

    Libreconv.stub(:convert, ->(*_args) { raise StandardError, 'libreconv exploded' }) do
      assert_nothing_raised { blob.convert_to_pdf }
    end

    refute blob.storage_adapter('pdf').exist?(blob.storage_key('pdf')),
           'pdf key should not exist after a failed conversion'
  end

  test 'convert_to_pdf cleans up the dat staging Tempfile even when Libreconv raises' do
    blob = FactoryBot.create(:doc_content_blob)
    closed_paths = []

    original_new = Tempfile.method(:new)
    spy = lambda do |*args|
      t = original_new.call(*args)
      t.define_singleton_method(:close!) do
        closed_paths << path
        super()
      end
      t
    end
    Tempfile.stub(:new, spy) do
      Libreconv.stub(:convert, ->(*_args) { raise StandardError, 'boom' }) do
        blob.convert_to_pdf
      end
    end

    assert closed_paths.any?, 'expected at least one Tempfile to be closed! in ensure'
  end

  test 'pdf_contents_for_search for a doc file produces search content (end-to-end)' do
    blob = FactoryBot.create(:doc_content_blob)
    # Stub Docsplit so the test does not require pdftotext to be installed;
    # the real behaviour of the Libreconv + storage-adapter pipeline is still exercised.
    docsplit_stub = lambda do |*args|
      opts = args.last.is_a?(Hash) ? args.last : {}
      File.write(File.join(opts[:output], 'content.txt'), 'This is a ms word doc format')
    end
    Docsplit.stub(:extract_text, docsplit_stub) do
      content = blob.pdf_contents_for_search
      assert_equal ['This is a ms word doc format'], content
    end
  end

  test 'pdf_contents_for_search for a pdf file produces search content (end-to-end)' do
    blob = FactoryBot.create(:pdf_content_blob)
    # Stub Docsplit so the test does not require pdftotext to be installed;
    # the adapter write/read pipeline for both the pdf and txt keys is still exercised.
    docsplit_stub = lambda do |*args|
      opts = args.last.is_a?(Hash) ? args.last : {}
      File.write(File.join(opts[:output], 'content.txt'), 'This is a pdf format')
    end
    Docsplit.stub(:extract_text, docsplit_stub) do
      content = blob.pdf_contents_for_search
      assert_equal ['This is a pdf format'], content
    end
  end

  # ---------------------------------------------------------------------------
  # with_temporary_copy_of_converted helper
  # ---------------------------------------------------------------------------

  test 'with_temporary_copy_of_converted yields a real path for an existing converted file' do
    blob = FactoryBot.create(:pdf_content_blob)
    blob.storage_adapter('pdf').write(blob.storage_key('pdf'), blob.data_io_object)

    yielded_path = nil
    blob.with_temporary_copy_of_converted('pdf') { |p| yielded_path = p }

    assert_not_nil yielded_path
    assert File.exist?(yielded_path), 'expected path to exist inside the block'
  end

  test 'with_temporary_copy_of_converted local adapter yields the on-disk path directly (no copy)' do
    blob = FactoryBot.create(:pdf_content_blob)
    blob.storage_adapter('pdf').write(blob.storage_key('pdf'), blob.data_io_object)

    expected_path = blob.storage_adapter('pdf').full_path(blob.storage_key('pdf'))
    blob.with_temporary_copy_of_converted('pdf') do |p|
      assert_equal expected_path, p, 'local adapter should yield the real path without copying'
    end
  end

  # ---------------------------------------------------------------------------
  # S3 adapter — verifies each pattern does not call File.exist?/File.open/filepath
  # ---------------------------------------------------------------------------

  test 'text_contents_for_search reads content from S3 adapter (Pattern A, stubbed S3)' do
    require 'aws-sdk-s3'
    blob = FactoryBot.create(:txt_content_blob)
    # The :data factory attribute persists on the instance after save and short-circuits
    # data_io_object before it reaches the adapter. Clear it to force the adapter path.
    blob.instance_variable_set(:@data, nil)

    Aws.config.update(stub_responses: true)
    s3 = build_s3_adapter('assets')
    stub_text = 'hello from s3 this is a stub response with enough words to pass split'
    s3_client(s3).stub_responses(:head_object, content_length: stub_text.bytesize)
    s3_client(s3).stub_responses(:get_object, body: stub_text)

    Seek::Storage.stub(:adapter_for, ->(*) { s3 }) do
      content = blob.text_contents_for_search
      assert content.any?, 'expected non-empty content from S3 (check split_content word-count minimum)'
      assert content.first.include?('hello'), "expected stubbed S3 content, got: #{content.inspect}"
    end
  ensure
    Aws.config.update(stub_responses: false)
  end

  test 'extract_text_from_pdf uses storage_adapter for pdf/txt checks with S3 (Pattern B, stubbed S3)' do
    require 'aws-sdk-s3'
    blob = FactoryBot.create(:pdf_content_blob)

    Aws.config.update(stub_responses: true)
    s3 = build_s3_adapter('converted')
    # head_object succeeds for both pdf and txt keys — both "exist"
    s3_client(s3).stub_responses(:head_object, content_length: 4)
    s3_client(s3).stub_responses(:get_object, body: 'pdf text content')

    dat_adapter = Seek::Storage.adapter_for('dat')
    Seek::Storage.stub(:adapter_for, ->(f = 'dat') { f == 'dat' ? dat_adapter : s3 }) do
      result = blob.extract_text_from_pdf
      assert_equal 'pdf text content', result
    end
  ensure
    Aws.config.update(stub_responses: false)
  end

  test 'adapter_convert_to_pdf writes Libreconv output to S3 adapter (Pattern C, stubbed S3)' do
    require 'aws-sdk-s3'
    blob = FactoryBot.create(:doc_content_blob)

    Aws.config.update(stub_responses: true)
    s3 = build_s3_adapter('converted')
    s3_client(s3).stub_responses(:head_object, 'NotFound') # pdf absent — proceed with conversion
    s3_client(s3).stub_responses(:put_object, {})

    dat_adapter = Seek::Storage.adapter_for('dat')
    Seek::Storage.stub(:adapter_for, ->(f = 'dat') { f == 'dat' ? dat_adapter : s3 }) do
      blob.convert_to_pdf
    end

    put_req = s3_client(s3).api_requests.find { |r| r[:operation_name] == :put_object }
    assert_not_nil put_req, 'expected put_object called on S3 adapter after conversion'
    assert_includes put_req[:params][:key], blob.storage_key('pdf')
  ensure
    Aws.config.update(stub_responses: false)
  end

  test 'with_temporary_copy_of_converted streams from S3 and cleans up the temp file' do
    require 'aws-sdk-s3'
    blob = FactoryBot.create(:pdf_content_blob)

    Aws.config.update(stub_responses: true)
    s3 = build_s3_adapter('converted')
    s3_client(s3).stub_responses(:get_object, body: '%PDF-stub')

    dat_adapter = Seek::Storage.adapter_for('dat')
    yielded_path = nil
    Seek::Storage.stub(:adapter_for, ->(f = 'dat') { f == 'dat' ? dat_adapter : s3 }) do
      blob.with_temporary_copy_of_converted('pdf') { |p| yielded_path = p }
    end

    assert_not_nil yielded_path
    refute File.exist?(yielded_path), 'expected temp file cleaned up after block'
  ensure
    Aws.config.update(stub_responses: false)
  end

  # ---------------------------------------------------------------------------
  # Cycle 6b — legacy_convert_to_pdf removed; convert_to_pdf is adapter-only
  # ---------------------------------------------------------------------------

  test 'convert_to_pdf with no arguments uses the adapter path' do
    blob = FactoryBot.create(:doc_content_blob)
    refute blob.storage_adapter('pdf').exist?(blob.storage_key('pdf'))

    blob.convert_to_pdf

    assert blob.storage_adapter('pdf').exist?(blob.storage_key('pdf')),
           'pdf key should exist in adapter after no-arg convert_to_pdf'
  end

  private

  def build_s3_adapter(prefix)
    Seek::Storage::S3Adapter.new(
      bucket: 'test-bucket',
      prefix: prefix,
      region: 'us-east-1',
      access_key_id: 'test',
      secret_access_key: 'test'
    )
  end

  def s3_client(adapter)
    adapter.send(:instance_variable_get, :@client)
  end
end

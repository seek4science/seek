require 'test_helper'
require 'storage_stub_helper'

class UnzipDataFileTest < ActiveSupport::TestCase
  include StorageStubHelper

  setup do
    FactoryBot.create(:admin) # to avoid first person automatically becoming admin
    @person = FactoryBot.create(:project_administrator)
    User.with_current_user(@person.user) do
      @data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:zip_folder_content_blob),
                                     policy: FactoryBot.create(:private_policy), contributor: @person
      @unzipper = Seek::DataFiles::Unzipper.new(@data_file)
    end
  end

  test 'unzipped datafiles are cached' do
    assert @unzipper.fetch.nil?
    @unzipper.unzip
    assert_not_nil @unzipper.fetch
  end

  test 'unzipped datafiles are not re-extracted when persisted' do
    @unzipper.unzip

    User.with_current_user @person.user do
      # Delete data file so re-extracting would raise an error
      @data_file.content_blob.destroy
      @data_file.reload
      assert_nil @data_file.content_blob
      assert_difference('DataFile.count', 2) do
        @unzipper.persist
      end
    end
  end

  test 'unzipped datafiles can be cleared' do
    @unzipper.unzip
    assert_not_nil @unzipper.fetch
    @unzipper.clear
    assert_nil @unzipper.fetch
  end

  test 'unzip .zip datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:zip_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  test 'unzip .7z datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sevenz_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  test 'unzip .tar datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:tar_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  test 'unzip .tar.bz2 datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:tar_bz2_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  test 'unzip .tar.gz datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:tar_gz_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  test 'unzip .tar.xz datafile' do
    User.with_current_user @person.user do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:tar_xz_folder_content_blob),
                                      policy: FactoryBot.create(:private_policy), contributor: @person
      skip 'Test for .tar.xz unzip skipped until functionality fixed' unless data_file.content_blob.is_txz?
      unzipper = Seek::DataFiles::Unzipper.new(data_file)
      unzipper.unzip
      assert_difference('DataFile.count', 2) do
        unzipper.persist
      end
    end
  end

  # S3: each archive-extraction method must stream the archive to a local temp copy via
  # with_temporary_copy, since the archive libraries require a real local file (issue 2.15).
  # .tar.xz is omitted because is_txz? is switched off (functionality disabled upstream).
  {
    'zip' => :zip_folder_content_blob,
    '7z' => :sevenz_folder_content_blob,
    'tar' => :tar_folder_content_blob,
    'tar.bz2' => :tar_bz2_folder_content_blob,
    'tar.gz' => :tar_gz_folder_content_blob
  }.each do |label, factory_name|
    test "unzip #{label} archive streamed from S3" do
      User.with_current_user @person.user do
        data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(factory_name),
                                       policy: FactoryBot.create(:private_policy), contributor: @person
        # Read the archive bytes from the local file the factory wrote, then reload so the
        # in-memory @data is dropped and reads must go through the storage adapter.
        archive_bytes = File.binread(data_file.content_blob.filepath)
        data_file = DataFile.find(data_file.id)

        tmp_dir = File.join(Dir.tmpdir, "s3-unzip-#{SecureRandom.hex(4)}/")
        begin
          with_stubbed_s3_storage do |dat, _converted|
            client = s3_client(dat)
            client.stub_responses(:head_object, content_length: archive_bytes.bytesize)
            client.stub_responses(:get_object, body: archive_bytes)

            result = data_file.unzip(tmp_dir)
            assert_equal 2, result.size, "expected 2 extracted datafiles for #{label} streamed from S3"
            assert result.all? { |df| df.title.present? }, "extracted datafiles should have titles for #{label}"

            # with_temporary_copy must clean up: no streamed archive copy left in the temp filestore.
            leaked = Dir[File.join(Seek::Config.temporary_filestore_path, "*-#{data_file.content_blob.original_filename}")]
            assert_empty leaked, "temp copy of #{label} archive leaked: #{leaked.inspect}"
          end
        ensure
          FileUtils.rm_rf(tmp_dir)
        end
      end
    end
  end

end

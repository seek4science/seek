require 'test_helper'

class UnzipDataFileTest < ActiveSupport::TestCase
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

end

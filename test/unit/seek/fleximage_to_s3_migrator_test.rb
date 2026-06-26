require 'test_helper'
require 'storage_stub_helper'
require 'seek/storage/fleximage_to_s3_migrator'

# Covers migrating legacy on-disk Avatar/ModelImage master images to S3 (Step 06, Option A').
# Records are created on the local backend so their master stays on disk, then the migrator runs
# under a stubbed S3 backend. Runs are scoped to specific records (via relations) to avoid picking
# up any other avatars/model images in the test database.
class FleximageToS3MigratorTest < ActiveSupport::TestCase
  include StorageStubHelper

  PNG = "#{Rails.root}/test/fixtures/files/file_picture.png".freeze

  setup do
    @output = StringIO.new
  end

  test 'copies legacy on-disk avatar and model image to S3' do
    avatar = create_local_avatar
    model_image = create_local_model_image
    assert File.exist?(avatar.file_path), 'avatar master should be on local disk'
    assert File.exist?(model_image.file_path), 'model image master should be on local disk'

    avatar_size = File.size(avatar.file_path)
    image_size  = File.size(model_image.file_path)

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      # Per record: exist? (NotFound) then verify-upload size. Avatar is processed before ModelImage.
      client.stub_responses(:head_object,
                            ['NotFound', { content_length: avatar_size },
                             'NotFound', { content_length: image_size }])
      client.stub_responses(:put_object, [{}])

      result = run_for(avatar, model_image)
      assert_equal 2, result.copied
      assert_equal 0, result.failed
      assert_equal 0, result.missing
    end
  end

  test 'skips an image already on S3 with matching size' do
    avatar = create_local_avatar
    size = File.size(avatar.file_path)

    with_stubbed_s3_storage do |dat, _converted|
      s3_client(dat).stub_responses(:head_object, [{ content_length: size }])
      result = run_for(avatar)
      assert_equal 1, result.skipped
      assert_equal 0, result.copied
    end
  end

  test 'counts missing when the local master file is absent' do
    avatar = create_local_avatar
    File.delete(avatar.file_path)

    with_stubbed_s3_storage do
      result = run_for(avatar)
      assert_equal 1, result.missing
      assert_includes @output.string, 'MISSING'
    end
  end

  test 'fails (does not overwrite) when S3 object has a different size' do
    avatar = create_local_avatar

    with_stubbed_s3_storage do |dat, _converted|
      s3_client(dat).stub_responses(:head_object, [{ content_length: 999_999 }])
      result = run_for(avatar)
      assert_equal 1, result.failed
      assert_includes @output.string, 'ERROR'
    end
  end

  test 'dry-run reports work without uploading' do
    avatar = create_local_avatar

    with_stubbed_s3_storage do |dat, _converted|
      client = s3_client(dat)
      client.stub_responses(:head_object, ['NotFound'])
      result = run_for(avatar, dry_run: true)
      assert_equal 1, result.copied
      assert_includes @output.string, 'DRY-RUN'
      assert client.api_requests.none? { |r| r[:operation_name] == :put_object },
             'put_object must not be called in dry-run'
    end
  end

  private

  def run_for(*records, dry_run: false)
    scopes = records.group_by(&:class).map { |klass, recs| klass.where(id: recs.map(&:id)) }
    Seek::Storage::FleximageToS3Migrator.new(dry_run: dry_run, output: @output).run(models: scopes)
  end

  def create_local_avatar
    owner = FactoryBot.create(:project)
    avatar = Avatar.new(owner: owner, image_file: File.open(PNG, 'rb'))
    disable_authorization_checks { avatar.save! }
    avatar
  end

  def create_local_model_image
    model = FactoryBot.create(:model)
    image = ModelImage.new(model: model, original_filename: 'file_picture.png',
                           content_type: 'image/png', image_file: File.open(PNG, 'rb'))
    disable_authorization_checks { image.save! }
    image
  end
end

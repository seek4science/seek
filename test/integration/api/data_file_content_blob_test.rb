require 'test_helper'

class DataFileContentBlobTest < ActionDispatch::IntegrationTest
  include ApiTestHelper

  def setup
    @person = FactoryBot.create(:person)
    @project = @person.projects.first
    @token = @person.user.api_tokens.create(title: 'test').token
    @current_user = @person.user
  end

  test 'can add create and add content to data file through API' do
    with_config_value(:auth_lookup_enabled, true) do
      df_params = load_template('post_min_data_file.json.erb')
      headers = {
        'Accept' => 'application/vnd.api+json',
        'Authorization' => "Token #{@token}"
      }

      post data_files_path, params: df_params, as: :json, headers: headers

      assert_response :success
      df = assigns(:data_file)
      assert df.content_blob.no_content?
      assert df.can_download?(@current_user)
      assert df.can_edit?(@current_user)
      original_md5 = df.content_blob.md5sum

      put data_file_content_blob_path(df, df.content_blob), headers: headers.merge({ 'RAW_POST_DATA' => File.binread(File.join(Rails.root, 'test', 'fixtures', 'files', 'a_pdf_file.pdf')) })

      assert_response :success
      blob = df.content_blob.reload
      refute_equal original_md5, blob.reload.md5sum
      refute blob.no_content?
      assert blob.file_size > 0
    end
  end
end

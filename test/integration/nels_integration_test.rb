require 'test_helper'

class NelsIntegrationTest < ActionDispatch::IntegrationTest
  fixtures :assay_classes

  include MockHelper
  include NelsTestHelper
  include HtmlHelper

  setup do
    setup_nels
  end

  test 'fills metadata when registering a data file' do
    @assay.investigation.projects << FactoryBot.create(:project)
    projects = @assay.reload.projects

    assert_no_difference('DataFile.count') do
      assert_no_difference('Assay.count') do
        assert_difference('ContentBlob.count', 1) do
          VCR.use_cassette('nels/get_dataset') do
            VCR.use_cassette('nels/get_persistent_url') do
              post register_assay_nels_path(assay_id: @assay.id, project_id: @project_id, dataset_id: @dataset_id, subtype_name: @subtype)

              assert_redirected_to provide_metadata_data_files_path(project_ids: projects.map(&:id))
              follow_redirect!

              assert_select '#data_file_title[value=?]', 'Illumina-sequencing-dataset - reads'

              selected_assay_ids = JSON.parse(select_node_contents('#assay_asset_list script')).map { |aa| aa['assay']['id'] }
              assert_includes selected_assay_ids, @assay.id

              selected_project_ids = select_node_contents('#project-selector-script').scan(/Sharing\.projectsSelector\.add\(([0-9]+), true\);/).flatten.map(&:to_i)
              assert_equal projects.map(&:id).sort, selected_project_ids.sort
            end
          end
        end
      end
    end
  end

  private

  def login_as(user)
    User.current_user = user
    post '/session', params: { login: user.login, password: generate_user_password }
  end
end

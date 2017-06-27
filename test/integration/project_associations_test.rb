require 'test_helper'

class ProjectAssociationsTest < ActionDispatch::IntegrationTest
  ASSETS_WITH_MULTIPLE_PROJECTS = %w(data_files events investigations models publications sops presentations samples publications)
  def setup
    User.current_user = Factory(:user, login: 'test')
    post '/session', login: 'test', password: 'blah'
  end

  test 'form allows setting project_ids' do
    skip 'This test no longer works with the dynamic project selector'
    ASSETS_WITH_MULTIPLE_PROJECTS.each do |type_name|
      if type_name == 'samples'
        get "/#{type_name}/new?sample_type_id=#{Factory(:simple_sample_type).id}"
      else
        get "/#{type_name}/new"
      end

      assert_select 'form select[name=?]', "#{type_name.singularize}[project_ids][]"

      get "/#{type_name}/#{Factory(type_name.singularize.to_sym, policy: Factory(:public_policy)).id}/edit"
      assert_select 'form select[name=?]', "#{type_name.singularize}[project_ids][]"
    end
  end

  test 'choosing my project in the sharing form adds permissions for each project' do
    skip 'This test no longer works with the dynamic permissions form'
    # publications are skipped, because they don't have a sharing form
    ASSETS_WITH_MULTIPLE_PROJECTS.reject { |t| t == 'publications' }.each do |type_name|
      item = Factory(type_name.singularize.to_sym, contributor: User.current_user)

      item.projects = [Factory(:project), Factory(:project)]
      disable_authorization_checks do
        put "/#{type_name}/#{item.id}", "#{item.class.name.downcase}".to_sym => { id: item.id },
                                        :sharing => { "access_type_#{Policy::ALL_USERS}" => Policy::VISIBLE, :your_proj_access_type => Policy::ACCESSIBLE }
      end

      item.reload
      assert_equal 2, item.policy.permissions.count, "wrong value for #{type_name}"
    end
  end
end

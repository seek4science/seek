require 'test_helper'


class ChangeProjectToProjectsTest < ActionController::IntegrationTest
  ASSETS_WITH_MULTIPLE_PROJECTS = %w[data_files events investigations models publications sops samples specimens]

  def setup
    User.current_user = Factory(:user, :login => 'test')
    post '/sessions/create', :login => 'test', :password => 'blah'
    Seek::Config.is_virtualliver = true
  end

  test 'form allows setting project_ids' do
    #TODO: update publications edit/new
    ASSETS_WITH_MULTIPLE_PROJECTS.each do |type_name|
      p type_name
      p 'new'
      get "/#{type_name}/new"
      assert_select "form select[name=?]", "#{type_name.singularize}[project_ids][]"

      types_with_no_select_on_edit_page = %w[models sops]

      p 'edit'
      get "/#{type_name}/#{Factory(type_name.singularize.to_sym, :policy => Factory(:public_policy)).id}/edit"
      unless types_with_no_select_on_edit_page.include? type_name
        assert_select "form select[name=?]", "#{type_name.singularize}[project_ids][]"
      else
        assert_select "form b", {:text => 'Projects:'}
      end
    end
  end

  test 'choosing my project in the sharing form adds permissions for each project' do
    #publications are skipped, because they don't have a sharing form
    ASSETS_WITH_MULTIPLE_PROJECTS.reject { |t| t=='publications' }.each do |type_name|
      p type_name
      item = Factory(type_name.singularize.to_sym, :contributor => User.current_user)
      item.projects = [Factory(:project), Factory(:project)]

      post "/#{type_name}/update/#{item.id}", :sharing=>{"access_type_#{Policy::ALL_SYSMO_USERS}"=>Policy::VISIBLE, :sharing_scope=>Policy::ALL_SYSMO_USERS, :your_proj_access_type => Policy::ACCESSIBLE}
      item.reload
      assert_equal 2, item.policy.permissions.count
    end
  end
end

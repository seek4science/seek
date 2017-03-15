require 'test_helper'

class NewMemberAffiliationDetailsTest < ActiveSupport::TestCase
  def setup
    @projects = [Factory(:project, title: 'First project'), Factory(:project, title: 'Second project')]
    @institutions = [Factory(:institution, title: 'First institution'), Factory(:institution, title: 'Second institution')]
  end

  test 'one project and institution' do
    project_id = @projects.first.id
    institution_id = @institutions.first.id
    params = { projects: [project_id], institutions: [institution_id] }
    message = Seek::Mail::NewMemberAffiliationDetails.new(params).message
    assert_equal "Project: First project\r\nInstitution: First institution", message
  end

  test 'multiple projects and institutions' do
    params = { projects: @projects.collect(&:id), institutions: @institutions.collect(&:id) }
    message = Seek::Mail::NewMemberAffiliationDetails.new(params).message
    assert_equal "Project: First project\r\nProject: Second project\r\nInstitution: First institution\r\nInstitution: Second institution", message
  end

  test 'with a new project and institution' do
    project_id = @projects.first.id
    institution_id = @institutions.first.id
    params = { projects: [project_id], institutions: [institution_id], other_projects: 'Other projects', other_institutions: 'Other institutions' }
    message = Seek::Mail::NewMemberAffiliationDetails.new(params).message
    assert_equal "Project: First project\r\nNew Projects: Other projects\r\nInstitution: First institution\r\nNew Institutions: Other institutions", message
  end

  test 'unknown project and instition id' do
    project_id = @projects.first.id
    institution_id = @institutions.first.id
    params = { projects: [project_id, 9_999_999], institutions: [institution_id, 999_999] }
    message = Seek::Mail::NewMemberAffiliationDetails.new(params).message
    assert_equal "Project: First project\r\nInstitution: First institution", message
  end
end

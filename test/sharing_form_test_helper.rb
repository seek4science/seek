module SharingFormTestHelper
  def valid_sharing
    {
      access_type: Policy::VISIBLE,
      permissions_attributes: {}
    }
  end

  def project_permissions(projects, access_type = Policy::ACCESSIBLE)
    {}.tap do |h|
      projects.each_with_index do |project, i|
        h["#{i}"] = {
          contributor_type: 'Project',
          contributor_id: project.is_a?(Project) ? project.id : project,
          access_type: access_type
        }
      end
    end
  end

  def projects_policy(access_type, projects, projects_access_type)
    {}.tap do |h|
      h[:access_type] = access_type
      h2 = {}
      projects.each_with_index do |project, i|
        h2["#{i}"] = {
          contributor_type: 'Project',
          contributor_id: project.is_a?(Project) ? project.id : project,
          access_type: projects_access_type
        }
      end
      h[:permissions_attributes] = h2
    end
  end
end

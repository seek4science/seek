module SharingFormTestHelper
  def valid_sharing
    {
        access_type: Policy::VISIBLE,
        permissions_attributes: { }
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

end

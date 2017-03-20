module SopsHelper
  def authorised_sops(projects = nil)
    authorised_assets(Sop, projects)
  end
end

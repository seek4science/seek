module PresentationsHelper

  def authorised_presentations(projects = nil)
    authorised_assets(Presentation, projects)
  end

end

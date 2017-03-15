module EventsHelper
  def authorised_events(projects = nil)
    authorised_assets(Event, projects)
  end
end

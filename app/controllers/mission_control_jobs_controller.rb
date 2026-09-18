# Base controller for the Mission Control - Jobs dashboard (mounted at /jobs). The engine's own
# controllers inherit from this, so gating it here reuses SEEK's existing admin authentication
# (login_required + is_user_admin_auth) rather than the gem's default HTTP Basic auth - only a
# logged-in admin can reach the queue dashboard.
class MissionControlJobsController < ApplicationController
  before_action :login_required
  before_action :is_user_admin_auth
  before_action :record_seek_return_path

  helper_method :seek_return_path

  private

  # Remembers the SEEK page the dashboard was entered from, for the back link in
  # app/views/layouts/mission_control/jobs/_application_selection.html.erb.
  def record_seek_return_path
    path = seek_referer_path
    session[:jobs_dashboard_return_path] = path if path
  end

  # The referer as a path within SEEK, or nil when there is nothing to go back to.
  def seek_referer_path
    referer = URI.parse(request.referer.to_s)
    return unless returnable_referer?(referer)

    [referer.path, referer.query].compact_blank.join('?')
  rescue URI::InvalidURIError
    nil
  end

  # Somewhere in SEEK we can send them back to - not a missing referer, not another host, and not
  # another dashboard page, so that the entry point survives navigating around the dashboard.
  def returnable_referer?(referer)
    return false unless referer.host.blank? || referer.host == request.host

    referer.path.present? && !jobs_dashboard_path?(referer.path)
  end

  def jobs_dashboard_path?(path)
    dashboard = main_app.mission_control_jobs_path
    path == dashboard || path.start_with?("#{dashboard}/")
  end

  # server_id is dropped because the engine's default_url_options adds it to every path generated
  # from one of its pages, including this one back out into SEEK.
  def seek_return_path
    session[:jobs_dashboard_return_path].presence || main_app.root_path(server_id: nil)
  end
end

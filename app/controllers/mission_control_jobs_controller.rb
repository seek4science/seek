# Base controller for the Mission Control - Jobs dashboard (mounted at /jobs on the experimental
# mission-control branch). The engine's own controllers inherit from this, so gating it here reuses
# SEEK's existing admin authentication (login_required + is_user_admin_auth) rather than the gem's
# default HTTP Basic auth - only a logged-in admin can reach the queue dashboard.
class MissionControlJobsController < ApplicationController
  before_action :login_required
  before_action :is_user_admin_auth
end

class ProgrammeStatsController < StatsController
  private

  def stats
    Seek::Stats::ProgrammeDashboardStats.new(@programme)
  end

  def get_scope
    name = t('programme')
    @scope = @programme = Programme.find_by_id(params[:programme_id])
    if @programme.nil?
      respond_to do |format|
        flash[:error] = "The #{name.humanize} does not exist!"
        format.html { redirect_to programme_path(@programme) }
      end
    end
  end

  def check_access_rights
    unless @programme.can_manage?
      flash[:error] = "You do not have permission to access this page."
      redirect_to programme_path(@programme)
      false
    end
  end
end

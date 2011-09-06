class SubscriptionsController < ApplicationController
  before_filter :login_required
  before_filter :find_and_auth, :only => [:destroy]

  def create
    @subscription = Subscription.new params[:subscription]
    respond_to do |format|
      if @subscription.save
        flash[:notice] = "You have subscribed to this #{@subscription.subscribable.class.name.humanize}"
        format.html { redirect_to(@subscription.subscribable) }
      else
        flash[:notice] = "You failed to subscribe to this #{@subscription.subscribable.class.name.humanize}"
        format.html { redirect_to(@subscription.subscribable) }
      end
    end
  end

  def destroy
    subscribable = @subscription.subscribable
    @subscription.destroy
    respond_to do |format|
      flash[:notice] = "You unsubscribed from this #{subscribable.class.name.humanize}"
      format.html { redirect_to(subscribable) }
      format.xml  { head :ok }
    end
  end
end

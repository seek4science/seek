class SubscriptionsController < ApplicationController
  before_action :login_required
  before_action :find_and_authorize_requested_item, :only => [:destroy]

  def create
    @subscription = current_user.person.subscriptions.build(subscription_params)
    respond_to do |format|
      if @subscription.save
        flash[:notice] = "You have subscribed to this #{@subscription.subscribable.class.name.humanize}"
        format.html { redirect_to(@subscription.subscribable) }
      else
        flash[:error] = "You failed to subscribe to this #{@subscription.subscribable.class.name.humanize}"
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
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:subscribable_id, :subscribable_type)
  end
end

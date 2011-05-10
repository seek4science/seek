class ExperimentalConditionsController < ApplicationController
  before_filter :login_required
  before_filter :find_and_auth_sop  
  before_filter :create_new_condition, :only=>[:index]

  include StudiedFactorsHelper

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@sop.experimental_conditions}
    end
  end

  def create    
    @experimental_condition=ExperimentalCondition.new(params[:experimental_condition])
    @experimental_condition.sop=@sop
    @experimental_condition.sop_version = params[:version]
    @experimental_condition.substance = find_or_create_substance
    
    render :update do |page|
      if @experimental_condition.save
        page.insert_html :bottom,"experimental_conditions_rows",:partial=>"condition_row",:object=>@experimental_condition,:locals=>{:show_delete=>true}
        page.visual_effect :highlight,"experimental_conditions"
        #page.visual_effect :highlight,"experimental_condition_row_#{@experimental_condition.id}"
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
    end
    
  end

  def destroy
    @experimental_condition=ExperimentalCondition.find(params[:id])

    render :update do |page|
      if @experimental_condition.destroy
        page.visual_effect :fade,"experimental_condition_row_#{@experimental_condition.id}"
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
    end
  end


  private

  def find_and_auth_sop
    begin
      sop = Sop.find(params[:sop_id])
      the_action=action_name
      the_action="edit" if the_action=="destroy" #we are not destroying the sop, just editing its exp conditions
      if Authorization.is_authorized?(the_action, nil, sop, current_user)
        @sop = sop
        @display_sop = params[:version] ? @sop.find_version(params[:version]) : @sop.latest_version
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to sops_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the SOP or you are not authorized to view it"
        format.html { redirect_to sops_path }
      end
      return false
    end

  end

  def create_new_condition
    @experimental_condition=ExperimentalCondition.new(:sop=>@sop)
  end
end


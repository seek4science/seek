class ExperimentalConditionsController < ApplicationController
  include Seek::FactorStudied
  include Seek::AnnotationCommon
  include Seek::AssetsCommon

  before_action :login_required
  before_action :find_and_auth_sop
  before_action :create_new_condition, :only=>[:index]
  before_action :no_comma_for_decimal, :only=>[:create, :update]

  include Seek::BreadCrumbs

  def index
    respond_to do |format|
      format.html
      format.xml {render :xml=>@sop.experimental_conditions}
    end
  end

  def create
    @experimental_condition=ExperimentalCondition.new(experimental_condition_params)
    @experimental_condition.sop=@sop
    @experimental_condition.sop_version = params[:version]
    substances = find_or_new_substances(params[:substance_list])
    substances.each do |substance|
      @experimental_condition.experimental_condition_links.build(:substance => substance )
    end

    update_annotations(params[:annotation][:value], @experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}

    if @experimental_condition.save
      respond_to do |format|
        format.js
      end
    else
      render plain: @experimental_condition.errors.full_messages, status: :unprocessable_entity
    end
  end

  def create_from_existing
    new_experimental_conditions = []
    #create the new FSes based on the selected FSes
    existing_experimental_condition_params[:existing_studied_factor].each do |id|
      experimental_condition = ExperimentalCondition.find(id)
      new_experimental_condition = ExperimentalCondition.new(:measured_item_id => experimental_condition.measured_item_id, :unit_id => experimental_condition.unit_id, :start_value => experimental_condition.start_value)
      new_experimental_condition.sop=@sop
      new_experimental_condition.sop_version = params[:version]
      experimental_condition.experimental_condition_links.each do |ecl|
         new_experimental_condition.experimental_condition_links.build(:substance => ecl.substance)
      end
      params[:annotation] = {}
      params[:annotation][:value] = try_block{Annotation.for_annotatable(experimental_condition.class.name, experimental_condition.id).with_attribute_name('description').first.value.text}
      update_annotations(params[:annotation][:value], new_experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}

      new_experimental_conditions.push new_experimental_condition
    end

    @saved_conditions, @errored_conditions = new_experimental_conditions.partition(&:save)
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @experimental_condition=ExperimentalCondition.find(params[:id])

    if @experimental_condition.destroy
      render js: "$j('#condition_or_factor_row_#{@experimental_condition.id}').fadeOut();"
    else
      render plain: @experimental_condition.errors.full_messages, status: :unprocessable_entity
    end
  end

  def update
      @experimental_condition = ExperimentalCondition.find(params[:id])

      new_substances = params["#{@experimental_condition.id}_substance_autocompleter_unrecognized_items"] || []
      known_substance_ids_and_types = params["#{@experimental_condition.id}_substance_autocompleter_selected_ids"] || []
      substances = find_or_new_substances(params[:substance_list])

      #delete the old experimental_condition_links
      @experimental_condition.experimental_condition_links.each do |ecl|
        ecl.destroy
      end

      #create the new experimental_condition_links
      experimental_condition_links = []
      substances.each do |substance|
        experimental_condition_links.push ExperimentalConditionLink.new(:substance => substance)
      end
      @experimental_condition.experimental_condition_links = experimental_condition_links

      update_annotations(params[:annotation][:value], @experimental_condition, 'description') if try_block{!params[:annotation][:value].blank?}


      if @experimental_condition.update_attributes(experimental_condition_params)
        respond_to do |format|
          format.js
        end
      else
        render plain: @experimental_condition.errors.full_messages, status: :unprocessable_entity
      end
  end

  private

  def experimental_condition_params
    params.require(:experimental_condition).permit(:measured_item_id, :unit_id, :start_value)
  end

  def existing_experimental_condition_params
    params.permit(existing_studied_factor: [])
  end

  def find_and_auth_sop
    begin
      sop = Sop.find(params[:sop_id])
      if sop.can_edit? current_user
        @sop = sop
        find_display_asset @sop
      else
        respond_to do |format|
          flash[:error] = "You are not authorized to perform this action"
          format.html { redirect_to sops_path }
        end
        return false
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        flash[:error] = "Couldn't find the #{t('sop')} or you are not authorized to view it"
        format.html { redirect_to sops_path }
      end
      return false
    end

  end

  def create_new_condition
    @experimental_condition=ExperimentalCondition.new(:sop=>@sop)
  end
end


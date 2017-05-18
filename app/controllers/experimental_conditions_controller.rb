class ExperimentalConditionsController < ApplicationController
  include Seek::FactorStudied
  include Seek::AnnotationCommon
  include Seek::AssetsCommon

  before_filter :login_required
  before_filter :find_and_auth_sop  
  before_filter :create_new_condition, :only=>[:index]
  before_filter :no_comma_for_decimal, :only=>[:create, :update]

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

    render :update do |page|
      if @experimental_condition.save
        page.insert_html :bottom,"condition_or_factor_rows",:partial=>"studied_factors/condition_or_factor_row",:object=>@experimental_condition,:locals=>{:asset => 'sop', :show_delete=>true}
        page.visual_effect :highlight,"condition_or_factor_rows"
        # clear the _add_factor form
        page.call "autocompleters['substance_autocompleter'].deleteAllTokens"
        page[:add_condition_or_factor_form].reset
        page[:substance_condition_factor].hide
        page[:growth_medium_or_buffer_description].hide
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
    end
  end

  def create_from_existing
    experimental_condition_ids = []
    new_experimental_conditions = []
    #retrieve the selected FSes
    params.each do |key, value|
       if key =~ /checkbox_/
         experimental_condition_ids.push value.to_i
       end
    end
    #create the new FSes based on the selected FSes
    experimental_condition_ids.each do |id|
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
    #
    render :update do |page|
        new_experimental_conditions.each do  |ec|
          if ec.save
            page.insert_html :bottom,"condition_or_factor_rows",:partial=>"studied_factors/condition_or_factor_row",:object=>ec,:locals=>{:asset => 'sop', :show_delete=>true}
          else
            page.alert("can not create factor studied: item: #{try_block{ec.substance.name}} #{ec.measured_item.title}, value: #{ec.start_value}}#{ec.unit.title}")
          end
        end
        page.visual_effect :highlight,"condition_or_factor_rows"
    end
  end

  def destroy
    @experimental_condition=ExperimentalCondition.find(params[:id])
    render :update do |page|
      if @experimental_condition.destroy
        page.visual_effect :fade, "condition_or_factor_row_#{@experimental_condition.id}"
        page.visual_effect :fade, "edit_condition_or_factor_#{@experimental_condition.id}_form"
      else
        page.alert(@experimental_condition.errors.full_messages)
      end
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
        render :update do |page|
          page.visual_effect :fade,"edit_condition_or_factor_#{@experimental_condition.id}_form"
          page.call "autocompleters['#{@experimental_condition.id}_substance_autocompleter'].deleteAllTokens"
          page.replace "condition_or_factor_row_#{@experimental_condition.id}", :partial => 'studied_factors/condition_or_factor_row', :object => @experimental_condition, :locals=>{:asset => 'sop', :show_delete=>true}
        end
      else
        render :update do |page|
          page.alert(@experimental_condition.errors.full_messages)
        end
      end
  end

  private

  def experimental_condition_params
    params.require(:experimental_condition).permit(:measured_item_id, :unit_id, :start_value)
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


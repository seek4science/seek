class SuggestedTechnologyTypesController < ApplicationController

  # all login users can edit their OWN created technology types
  # only admins can manage(i.e. edit and delete)
  before_filter :check_allowed_to_manage_types, :only => [:destroy, :manage]

  before_filter :project_membership_required_appended, :only => [:new_popup, :manage]
  before_filter :find_and_authorize_requested_item, :only => [:edit, :destroy]

  def new_popup
    @suggested_technology_type = SuggestedTechnologyType.new
    @suggested_technology_type.link_from= params[:link_from]
    respond_to do |format|
      format.html { render :layout => false }
      format.xml { render :xml => @suggested_technology_type }
    end
  end

  def new
    @suggested_technology_type = SuggestedTechnologyType.new
    respond_to do |format|
      format.html
      format.xml { render :xml => @suggested_technology_type }
    end
  end


  def edit
    @suggested_technology_type.link_from= params[:link_from]
    respond_to do |format|
      format.html
      format.js
      format.xml { render :xml => @suggested_technology_type }
    end
  end


  def create
    @suggested_technology_type = SuggestedTechnologyType.new(params[:suggested_technology_type])
    @suggested_technology_type.contributor_id= User.current_user.try(:person_id)
    saved = @suggested_technology_type.save
    if @suggested_technology_type.link_from == "assays"
      render :update do |page|
        if saved
          page.call "RedBox.close"
          page.replace_html 'assay_technology_types_list', :partial => "assays/technology_types_list", :locals => {:suggested_technology_type => @suggested_technology_type}
        else
          page.alert("Fail to create new technology type. #{@suggested_technology_type.errors.full_messages}")
        end
      end

    else
      respond_to do |format|
        if saved
          flash[:notice] = "technology type was successfully created."
          format.html { redirect_to(:action => "manage") }
          format.xml { head :ok }
        else
          format.html { render :action => :new }
          format.xml { render :xml => @suggested_technology_type.errors, :status => :unprocessable_entity }
        end
      end
    end

  end

  def update
    @suggested_technology_type=SuggestedTechnologyType.find(params[:id])
    @suggested_technology_type.attributes = params[:suggested_technology_type]
    saved = @suggested_technology_type.save
    if params[:commit_popup]
      render :update do |page|
        if saved
          page.replace_html 'assay_technology_types_list', :partial => "assays/technology_types_list", :locals => {:suggested_technology_type => @suggested_technology_type}
          page.call "RedBox.close"
        else
          page.alert("Fail to edit technology type. #{@suggested_technology_type.errors.full_messages}")
        end
      end

    else
      respond_to do |format|
        if saved
          flash[:notice] = "technology type was successfully updated."
          format.html { redirect_to(:action => "manage") }
          format.xml { head :ok }
        else
          format.html { render :action => :edit }
          format.xml { render :xml => @suggested_technology_type.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def manage
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def destroy
    respond_to do |format|
      if @suggested_technology_type.can_destroy?
        title = @suggested_technology_type.label
        @suggested_technology_type.destroy
        flash[:notice] = "Technology type #{title} was deleted."
        format.html { redirect_to(:action => "manage") }
        format.xml { head :ok }
      else
        if !@suggested_technology_type.children.empty?
          flash[:error]="Unable to delete technology types with children"
        elsif !@suggested_technology_type.get_child_assays.empty?
          flash[:error]="Unable to delete technology type due to reliance from #{@suggested_technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize} on child technology types"
        elsif !@suggested_technology_type.assays.empty?
          flash[:error]="Unable to delete technology type due to reliance from #{@suggested_technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize}"
        end
        format.html { redirect_to(:action => "manage") }
        format.xml { render :xml => @suggested_technology_type.errors, :status => :unprocessable_entity }
      end
    end
  end


end

class SuggestedAssayTypesController < ApplicationController
  # all login users can manage assay types by editing their own ones
  # admins can even delete them
  before_filter :check_allowed_to_manage_types, :only => [:destroy]

  before_filter :project_membership_required, :only => [:new]

  def new
    @suggested_assay_type = SuggestedAssayType.new
    @suggested_assay_type.is_for_modelling = string_to_boolean params[:is_for_modelling]
    @suggested_assay_type.link_from= params[:link_from]
    respond_to do |format|
      format.html { render :layout => false }
      format.xml { render :xml => @suggested_assay_type }
    end
  end

  def edit
    @suggested_assay_type=SuggestedAssayType.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :xml => @suggested_assay_type }
    end
  end

  def create
    @suggested_assay_type = SuggestedAssayType.new(params[:suggested_assay_type])
    @suggested_assay_type.contributor_id= User.current_user.try(:person_id)
    render :update do |page|
      if @suggested_assay_type.save
        page.call "RedBox.close"
        if @suggested_assay_type.link_from == "assays"
          page.replace_html 'assay_assay_types_list', :partial => "assays/assay_types_list", :locals => {:suggested_assay_type => @suggested_assay_type, :is_for_modelling => @suggested_assay_type.is_for_modelling}
        elsif @suggested_assay_type.link_from == "suggested_assay_types"
          page.redirect_to( :action => "manage")
        end
      else
        page.alert("Fail to create new assay type. #{@suggested_assay_type.errors.full_messages}")
      end

    end

  end

  def update
    @suggested_assay_type=SuggestedAssayType.find(params[:id])
    @suggested_assay_type.attributes = params[:suggested_assay_type]
    respond_to do |format|
      if @suggested_assay_type.save

        flash[:notice] = "#{t('assays.assay')} type was successfully updated."
        format.html { redirect_to( :action => "manage") }
        format.xml { head :ok }
      else
        format.html { render :action => :edit }
        format.xml { render :xml => @suggested_assay_type.errors, :status => :unprocessable_entity }
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
    @suggested_assay_type=SuggestedAssayType.find(params[:id])
    respond_to do |format|
      if @suggested_assay_type.can_destroy?
        title = @suggested_assay_type.label
        @suggested_assay_type.destroy
        flash[:notice] = "#{t('assays.assay')} type #{title} was deleted."
        format.html { redirect_to( :action => "manage") }
        format.xml { head :ok }
      else
        if !@suggested_assay_type.children.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} types with children"
        elsif !@suggested_assay_type.get_child_assays.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} type due to reliance from #{@suggested_assay_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize} on child #{t('assays.assay').downcase} types"
        elsif !@suggested_assay_type.assays.empty?
          flash[:error]="Unable to delete #{t('assays.assay').downcase} type due to reliance from #{@suggested_assay_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize}"
        end
        format.html { redirect_to(:action => "manage") }
        format.xml { render :xml => @suggested_assay_type.errors, :status => :unprocessable_entity }
      end
    end
  end



  private

  def string_to_boolean string
    if string=="true"
      return true
    elsif string == "false"
      return false
    else

    end
  end


end

class SuggestedTechnologyTypesController < ApplicationController
  # all login users can manage technology types by editing their own ones
  # admins can even delete them
  before_filter :check_allowed_to_manage_types, :only=> [:destroy]

   before_filter :project_membership_required, :only=>[:new]


    def new
      @suggested_technology_type = SuggestedTechnologyType.new
      @suggested_technology_type.link_from= params[:link_from]
      respond_to do |format|
        format.html { render :layout => false }
        format.xml { render :xml => @suggested_technology_type }
      end
    end

    def edit
      @suggested_technology_type=SuggestedTechnologyType.find(params[:id])
      @suggested_technology_type.link_from= params[:link_from]
      @suggested
      respond_to do |format|
        format.html
        format.xml { render :xml => @suggested_technology_type }
      end
    end


    def create
      @suggested_technology_type = SuggestedTechnologyType.new(params[:suggested_technology_type])
      @suggested_technology_type.contributor_id= User.current_user.try(:person_id)
      render :update do |page|
        if @suggested_technology_type.save
          page.call "RedBox.close"
          if @suggested_technology_type.link_from == "assays"
            page.replace_html 'assay_technology_types_list', :partial => "assays/technology_types_list", :locals => {:suggested_technology_type => @suggested_technology_type}
          elsif @suggested_technology_type.link_from == "suggested_technology_types"
            page.redirect_to( :action => "manage")
          end
        else
          page.alert("Fail to create new technology type. #{@suggested_technology_type.errors.full_messages}")
        end

      end

    end

    def update
      @suggested_technology_type=SuggestedTechnologyType.find(params[:id])
      @suggested_technology_type.attributes = params[:suggested_technology_type]
      respond_to do |format|
        if @suggested_technology_type.save

          flash[:notice] = "Technology type was successfully updated."
          format.html { redirect_to(:action => "manage") }
          format.xml { head :ok }
        else
          format.html { render :action => :edit }
          format.xml { render :xml => @suggested_technology_type.errors, :status => :unprocessable_entity }
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
      @suggested_technology_type=SuggestedTechnologyType.find(params[:id])
      respond_to do |format|
        if @suggested_technology_type.can_destroy?
          title = @suggested_technology_type.label
          @suggested_technology_type.destroy
          flash[:notice] = "Technology type #{title} was deleted."
          format.html { redirect_to( :action => "manage") }
          format.xml { head :ok }
        else
          if !@suggested_technology_type.children.empty?
            flash[:error]="Unable to delete technology types with children"
          elsif !@suggested_technology_type.get_child_assays.empty?
            flash[:error]="Unable to delete technology type due to reliance from #{@suggested_technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize} on child technology types"
          elsif !@suggested_technology_type.assays.empty?
            flash[:error]="Unable to delete technology type due to reliance from #{@suggested_technology_type.get_child_assays.count} existing #{t('assays.assay').downcase.pluralize}"
          end
          format.html { redirect_to( :action => "manage") }
          format.xml { render :xml => @suggested_technology_type.errors, :status => :unprocessable_entity }
        end
      end
    end





end

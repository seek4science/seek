module Seek
  module Ontologies
    module Controller
      module SuggestedTypeHandler
        extend ActiveSupport::Concern

        included do
          before_filter :check_allowed_to_manage_types, only: [:destroy, :manage]
          before_filter :project_membership_required_appended, only: [:manage]
          before_filter :find_and_authorize_requested_item, only: [:edit, :update, :destroy]
        end

        def model_class
          controller_name.classify.constantize
        end

        def new
          @suggested_type = model_class.new
          @suggested_type.term_type = params[:term_type]
          respond_to do |format|
            format.html { render template: 'suggested_types/new' }
            format.js { render template: 'suggested_types/new_popup', layout: false }
            format.xml { render xml: @suggested_type }
          end
        end

        def edit
          @suggested_type = eval("@#{controller_name.singularize}")
          @suggested_type.term_type = params[:term_type]
          respond_to do |format|
            format.html { render template: 'suggested_types/edit' }
            format.js { render template: 'suggested_types/edit.js.rjs' }
            format.xml { render xml: @suggested_type }
          end
        end

        def manage
          respond_to do |format|
            format.html { render template: 'suggested_types/manage' }
          end
        end

        def create
          attributes = params[controller_name.singularize.to_sym]
          @suggested_type = model_class.new(attributes)
          @suggested_type.contributor_id = User.current_user.try(:person_id)
          saved = @suggested_type.save
          respond_to do |format|
            format.js { render template: 'suggested_types/create.js.rjs' }

            if saved
              set_successful_flash_message("created")
              format.html { redirect_to(action: 'manage') }
              format.xml { head :ok }
            else
              format.html { render template: 'suggested_types/new' }
              format.xml { render xml: @suggested_type.errors, status: :unprocessable_entity }
            end
          end
        end

        def update
          @suggested_type = eval("@#{controller_name.singularize}")
          @suggested_type.update_attributes(params[controller_name.singularize.to_sym])
          saved = @suggested_type.save
          respond_to do |format|
            format.js { render template: 'suggested_types/create.js.rjs' }
            if saved
              set_successful_flash_message("updated")
              format.html { redirect_to(action: 'manage') }
              format.xml { head :ok }
            else
              format.html { render action: :edit }
              format.xml { render xml: @suggested_type.errors, status: :unprocessable_entity }
            end
          end
        end

        def destroy
          @suggested_type = eval("@#{controller_name.singularize}")
          respond_to do |format|
            if @suggested_type.can_destroy?
              @suggested_type.destroy
              set_successful_flash_message("destroyed")
              format.xml { head :ok }
            else
              flash[:error] = @suggested_type.destroy_errors.join('<br/>').html_safe
              format.xml { render xml: @suggested_type.errors, status: :unprocessable_entity }
            end
            format.html { redirect_to(action: 'manage') }
          end
        end

        def set_successful_flash_message(action)
          flash[:notice] = "#{@suggested_type.humanize_term_type} type #{@suggested_type.label} was successfully #{action}."
        end


      end
    end
  end
end

module Seek
  module Ontologies
    module Controller
      module SuggestedTypeHandler
        extend ActiveSupport::Concern

        included do
          before_filter :check_allowed_to_manage_types, only: %i[destroy index]
          before_filter :project_membership_required_appended, only: [:index]
          before_filter :find_and_authorize_requested_item, only: %i[edit update destroy]

          include Seek::BreadCrumbs
        end

        def model_class
          controller_name.classify.constantize
        end

        def new
          @suggested_type = model_class.new
          @suggested_type.term_type = params[:term_type]
          respond_to do |format|
            format.html { render template: 'suggested_types/new' }
            format.xml { render xml: @suggested_type }
          end
        end

        def edit
          @suggested_type = eval("@#{controller_name.singularize}")
          @suggested_type.term_type = params[:term_type]
          respond_to do |format|
            format.html { render template: 'suggested_types/edit' }
            format.xml { render xml: @suggested_type }
          end
        end

        def index
          respond_to do |format|
            format.html { render template: 'suggested_types/index' }
          end
        end

        def create
          @suggested_type = model_class.new(type_params)
          @suggested_type.contributor_id = User.current_user.try(:person_id)
          saved = @suggested_type.save
          respond_to do |format|
            if saved
              format.js { render template: 'suggested_types/create' }
              set_successful_flash_message('created')
              format.html { redirect_to(action: 'index') }
              format.xml { head :ok }
            else
              format.js   { render template: 'suggested_types/create', status: :unprocessable_entity }
              format.html { render template: 'suggested_types/new' }
              format.xml { render xml: @suggested_type.errors, status: :unprocessable_entity }
            end
          end
        end

        def update
          @suggested_type = eval("@#{controller_name.singularize}")
          @suggested_type.update_attributes(type_params)
          saved = @suggested_type.save
          respond_to do |format|
            if saved
              set_successful_flash_message('updated')
              format.html { redirect_to(action: 'index') }
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
              set_successful_flash_message('destroyed')
              format.xml { head :ok }
            else
              flash[:error] = @suggested_type.destroy_errors.join('<br/>').html_safe
              format.xml { render xml: @suggested_type.errors, status: :unprocessable_entity }
            end
            format.html { redirect_to(action: 'index') }
          end
        end

        def set_successful_flash_message(action)
          flash[:notice] = "#{@suggested_type.humanize_term_type} type #{@suggested_type.label} was successfully #{action}."
        end

        private

        def type_params
          params.require(controller_name.singularize.to_sym).permit(:label, :parent_uri)
        end
      end
    end
  end
end

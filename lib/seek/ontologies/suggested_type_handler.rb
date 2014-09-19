module Seek
  module Ontologies
    module SuggestedTypeHandler
      def model_class
        self.controller_name.classify.constantize
      end
      def new
        @suggested_type = model_class.new
        @suggested_type.term_type = params[:term_type]
        respond_to do |format|
          format.html { render :template => "suggested_types/new" }
          format.js { render :template => "suggested_types/new_popup", :layout => false }
          format.xml { render :xml => @suggested_type }
        end
      end

      def edit
        object = eval("@#{self.controller_name.singularize}")
        @suggested_type = object
        @suggested_type.term_type = params[:term_type]
        respond_to do |format|
          format.html { render :template => "suggested_types/edit" }
          format.js { render :template => "suggested_types/edit.js.rjs" }
          format.xml { render :xml => @suggested_type }
        end
      end
      def manage
          respond_to do |format|
            format.html { render :template => "suggested_types/manage"}
          end
      end
      def create
        @suggested_type = model_class.new(params[self.controller_name.singularize.to_sym])
        @suggested_type.contributor_id= User.current_user.try(:person_id)
        saved = @suggested_type.save

        respond_to do |format|
          format.js { render :template => "suggested_types/create.js.rjs" }

          if saved
            flash[:notice] = "#{@suggested_type.humanize_term_type} type #{@suggested_type.label} was successfully created."
            format.html { redirect_to(:action => "manage") }
            format.xml { head :ok }
          else
            format.html { render :template => "suggested_types/new" }
            format.xml { render :xml => @suggested_type.errors, :status => :unprocessable_entity }
          end
        end


      end

      def update
        @suggested_type=model_class.find(params[:id])
        @suggested_type.attributes = params[self.controller_name.singularize.to_sym]
        saved = @suggested_type.save
        respond_to do |format|
          format.js { render :template => "suggested_types/create.js.rjs" }
          if saved
            flash[:notice] = "#{@suggested_type.humanize_term_type} type was successfully updated."
            format.html { redirect_to(:action => "manage") }
            format.xml { head :ok }
          else
            format.html { render :action => :edit }
            format.xml { render :xml => @suggested_type.errors, :status => :unprocessable_entity }
          end
        end
      end


      def destroy
        object = eval("@#{self.controller_name.singularize}")
        @suggested_type = object
        respond_to do |format|
          if @suggested_type.can_destroy?
            title = @suggested_type.label
            @suggested_type.destroy
            flash[:notice] = "#{@suggested_type.humanize_term_type} type #{title} was deleted."
            format.xml { head :ok }
          else
            flash[:error] = @suggested_type.destroy_errors.join("<br/>").html_safe
            format.xml { render :xml => @suggested_type.errors, :status => :unprocessable_entity }
          end
          format.html { redirect_to(:action => "manage") }
        end
      end


    end
  end
end

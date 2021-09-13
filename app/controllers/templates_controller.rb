class TemplatesController < ApplicationController
    respond_to :html
    include Seek::IndexPager
    before_action :find_template, only: [:show]
    before_action :find_assets, only: [:index]
    before_action :auth_to_create, only: [:new, :create]

  
    def show
      respond_to do |format|
        format.html
      end
    end
  
    def new
      @tab = 'manual'
      @template = Template.new
      respond_with(@template)
    end
  
    def create
      @template = Template.new(template_params)
      @template.contributor = User.current_user.person
      @tab = 'manual'
  
      respond_to do |format|
        if @template.save
          format.html { redirect_to @template, notice: 'Template was successfully created.' }
        else
          format.html { render action: 'new' }
        end
      end
    end
  
    def destroy
      respond_to do |format|
      if @template.can_delete? && @template.destroy
        format.html { redirect_to @template,location: templates_path, notice: 'Template was successfully deleted.' }
      else
        format.html { redirect_to @template, location: templates_path, notice: 'It was not possible to delete the template.' }
      end
      end
    end
  
    private
  
    def template_params
      params.require(:template).permit(:title, :description, :tags, :template_id,
                                          { project_ids: [],
                                            template_attributes_attributes: [:id, :title, :required,
                                                                          :sample_attribute_type_id, :isa_tag_id,
                                                                          :sample_controlled_vocab_id,
                                                                          :unit_id, :_destroy]})
    end
  
    def find_template
      @template = Template.find(params[:id])
    end
  end
  
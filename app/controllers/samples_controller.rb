class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling

  before_filter :auth_to_create, :only=>[:new,:create]

  def new
    @sample = Sample.new(sample_type_id: params[:sample_type_id])
    respond_with(@sample)
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    @sample.update_attributes(params[:sample])
    flash[:notice] = 'The sample was successfully created.' if @sample.save
    respond_with(@sample)
  end

  def show
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def edit
    @sample = Sample.find(params[:id])
    respond_with(@sample)
  end

  def update
    @sample = Sample.find(params[:id])
    @sample.update_attributes(params[:sample])
    flash[:notice] = 'The sample was successfully updated.' if @sample.save
    respond_with(@sample)
  end

  def destroy
    @sample = Sample.find(params[:id])
    if @sample.can_delete? && @sample.destroy
      flash[:notice] = 'The sample was successfully deleted.'
    else
      flash[:notice] = 'It was not possible to delete the sample.'
    end
    respond_with(@sample,location:root_path)
  end

  #called from AJAX, returns the form containing the attributes for the sample_type_id
  def attribute_form
    sample_type_id = params[:sample_type_id]

    sample=Sample.new(sample_type_id:sample_type_id)


    respond_with do |format|
      format.js {
        render json: {
                form: (render_to_string(partial:"samples/sample_attributes_form",locals:{sample:sample}))
               }
      }
    end
  end

  def filter
    @samples = Sample.where("title LIKE ?" , "#{params[:filter]}%").limit(5)

    respond_with do |format|
      format.html { render :partial => 'samples/association_preview', :collection => @samples }
    end
  end

end

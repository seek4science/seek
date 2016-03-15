class SamplesController < ApplicationController
  respond_to :html
  include Seek::PreviewHandling
  include Seek::AssetsCommon
  include Seek::IndexPager

  before_filter :find_assets, :only => [ :index ]
  before_filter :find_and_authorize_requested_item, :except => [ :index, :new, :create, :preview]

  before_filter :auth_to_create, :only=>[:new,:create]


  def extract_from_data_file
    @rejected_samples = []
    @samples = []
    data_file = DataFile.find(params[:data_file_id])

    if data_file.possible_sample_types.count>=1
      sample_type = data_file.possible_sample_types.last
      samples = sample_type.build_samples_from_template(data_file.content_blob)
      samples.each do |sample|
        sample.contributor=User.current_user
        sample.originating_data_file = data_file
        if sample.valid? && sample.save
          @samples << sample
        else
          @rejected_samples << sample
        end
      end
    else

    end
    flash[:notice]="#{@samples.count} samples created, #{@rejected_samples.count} rejected"
    redirect_to samples_path
  end

  def new
    @sample = Sample.new(sample_type_id: params[:sample_type_id])
    respond_with(@sample)
  end

  def create
    @sample = Sample.new(sample_type_id: params[:sample][:sample_type_id], title: params[:sample][:title])
    update_sample_with_params
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
    update_sample_with_params
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
    @associated_samples = params[:assay_id].blank? ? [] : Assay.find(params[:assay_id]).samples
    @samples = Sample.where("title LIKE ?", "%#{params[:filter]}%").limit(20)

    respond_with do |format|
      format.html { render :partial => 'samples/association_preview', :collection => @samples,
                           :locals => { :existing => @associated_samples } }
    end
  end

  private

  def update_sample_with_params
    @sample.update_attributes(params[:sample])
    update_sharing_policies @sample, params
    update_annotations(params[:tag_list], @sample)
  end

end

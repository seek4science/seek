class OpenbisZamplesController < ApplicationController

  before_filter :get_seek_util
  before_filter :get_project
  before_filter :get_endpoint
  before_filter :get_zample, only: [:show, :edit, :update]
  before_filter :get_studies, only: [:edit]

  def index
    get_zamples
  end

  def show
  end

  def edit
    @assay=Assay.new
    #puts params
    #puts "ID: #{params[:id]}"
    @linked_to_assay = ['20171002172401546-38']
  end

  def update
    @linked_to_assay = ['20171002172401546-38']
    puts "update called"
    puts params

    #data_sets_ids = extract_requested_sets(@zample, params)
    #data_sets = Seek::Openbis::Dataset.new(@openbis_endpoint).find_by_perm_ids(data_sets_ids)

    # data_files = find_or_register_seek_files(data_sets)

    assay_params = params.require(:assay).permit(:study_id, :assay_class_id, :title);
    sync_options = params.permit(:link_datasets)

    @assay = @seek_util.createObisAssay(assay_params,current_person, @zample, sync_options)



    if @assay.save
      flash[:notice] = "Registered: #{params}"
      redirect_to @assay
    else
      @reasons = @assay.errors
      @error_msg = 'Could not create assay'
      render action: 'edit'
      # redirect_to edit_project_openbis_endpoint_openbis_zample_path
    end
  end

  def extract_requested_sets(zample, params)
    return zample.dataset_ids if params[:link_datasets] == '1'

    return (params[:linked_datasets] || []) & zample.dataset_ids
  end

  def find_or_register_seek_files(data_sets)

    data_sets.map do |set|
      df = set.registered_as
      if (df.nil?)
        df = DataFile.build_from_openbis_dataset(set)
        df.save!
      end
      df
    end
  end

  def get_studies
    investigations = Investigation.all.select &:can_view?
    @studies=[]
    investigations.each do |i|
      @studies << i.studies.select(&:can_view?)
    end
    @studies
  end

  def get_zample

    sample = Seek::Openbis::Zample.new(@openbis_endpoint)
    json = JSON.parse(
        '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40","20171004182824553-41"]
,"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )
    # @zample = sample.populate_from_json(json)

    @zample = Seek::Openbis::Zample.new(@openbis_endpoint, params[:id])
  end

  def get_zamples
    @zamples = []

    sample = Seek::Openbis::Zample.new(@openbis_endpoint)
    json = JSON.parse(
        '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40"],"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )
    sample = sample.populate_from_json(json)
    @zamples << sample

    sample = Seek::Openbis::Zample.new(@openbis_endpoint)
    json = JSON.parse(
        '{"identifier":"\/API-SPACE\/TZ4","modificationDate":"2017-10-02 16:26:39.055471","registerator":"apiuser","code":"TZ4","modifier":"apiuser","permId":"20171002172639055-39","registrationDate":"2017-10-02 16:26:39.055471","datasets":[],"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample\/assay with a dataset. Karolina. Longer description","NAME":"Tomek Second"},"tags":[]}'
    )
    sample = sample.populate_from_json(json)
    @zamples << sample

    @zamples = Seek::Openbis::Zample.new(@openbis_endpoint).all

  end

  def get_endpoint
    @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
  end

  def get_project
    @project = Project.find(params[:project_id])
  end

  def get_seek_util
    @seek_util = Seek::Openbis::SeekUtil.new unless @seek_util
  end
end
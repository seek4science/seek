class OpenbisZamplesController < ApplicationController

  before_filter :get_project
  before_filter :get_endpoint
  before_filter :get_zample, only: [:show, :edit]


  def index
    get_zamples
  end

  def show
  end

  def edit
  end

  def get_zample

    sample = Seek::Openbis::Zample.new(@openbis_endpoint)
    json = JSON.parse(
        '
{"identifier":"\/API-SPACE\/TZ3","modificationDate":"2017-10-02 18:09:34.311665","registerator":"apiuser",
"code":"TZ3","modifier":"apiuser","permId":"20171002172111346-37",
"registrationDate":"2017-10-02 16:21:11.346421","datasets":["20171002172401546-38","20171002190934144-40"],"sample_type":{"code":"TZ_FAIR_ASSAY","description":"For testing sample\/assay mapping with full metadata"},"properties":{"DESCRIPTION":"Testing sample assay with a dataset. Zielu","NAME":"Tomek First"},"tags":[]}
'
    )
    @zample = sample.populate_from_json(json)
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

  end

  def get_endpoint
    @openbis_endpoint = OpenbisEndpoint.find(params[:openbis_endpoint_id])
  end

  def get_project
    @project = Project.find(params[:project_id])
  end
end
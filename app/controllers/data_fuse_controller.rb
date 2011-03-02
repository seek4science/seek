class DataFuseController < ApplicationController
  include Seek::MimeTypes
  include Seek::ModelProcessing
  
  before_filter :login_required

  @@model_builder = Seek::JWSModelBuilder.new

  def show
    xls_types = mime_types_for_extension("xls")

    @data_files=Authorization.authorize_collection("download", DataFile.all, current_user).select do |df|
      xls_types.include?(df.content_type)
    end

    @models=Authorization.authorize_collection("download", Model.all, current_user).select { |m| @@model_builder.is_supported?(m) }
    respond_to do |format|
      format.html
    end
  end

  def assets_selected
    @data_file = DataFile.find(params[:data_file_id])
    @model=Model.find(params[:model_id])

    #FIXME: temporary way of making sure it isn't exploited to get at data. Should never get here if used through the UI
    raise Exception.new("Unauthorized") unless Authorization.is_authorized?("download", nil, @model, current_user) && Authorization.is_authorized?("download", nil, @data_file, current_user)

    @parameter_keys = params[:parameter_keys].keys
    respond_to do |format|
      format.html
    end
  end

  def parameter_keys

    element=params[:element]
    model=Model.find_by_id(params[:id])

    ps=extract_model_parameters_and_values(model).keys

    render :update do |page|
      if model && Authorization.is_authorized?("download", nil, model, current_user)

        page.replace_html element, :partial=>"data_fuse/parameter_keys", :locals=>{:keys=>ps}
      else
        page.replace_html element, :text=>"Model not found, or not authorized to examine"
      end
    end
  end

end

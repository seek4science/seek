require 'libxml'
require 'fastercsv'

class DataFuseController < ApplicationController
  include Seek::MimeTypes
  include Seek::ModelProcessing
  include SysMODB::SpreadsheetExtractor
  
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
    params[:parameter_keys] ||= {}

    #FIXME: temporary way of making sure it isn't exploited to get at data. Should never get here if used through the UI
    raise Exception.new("Unauthorized") unless Authorization.is_authorized?("download", nil, @model, current_user) && Authorization.is_authorized?("download", nil, @data_file, current_user)

    @parameter_keys = params[:parameter_keys].keys

    @matching_csv,@matched_keys = matching_csv(@data_file,@parameter_keys)

    respond_to do |format|
      format.html
    end
  end

  def matching_csv data_file,parameter_keys
    last_sheet_index = find_last_sheet_index(data_file)
    csv = spreadsheet_to_csv(open(data_file.content_blob.filepath),last_sheet_index,true)

    Seek::CSVHandler.resolve_model_parameter_keys parameter_keys,csv
    
  end



  def find_last_sheet_index data_file
    #FIXME: this currently uses the XML to find the number of sheets. The spreadsheet extractor will be updated to provide a summary including this
    #information in the future which will be more efficient

    xml = spreadsheet_to_xml(open(data_file.content_blob.filepath))

    parser = LibXML::XML::Parser.string(xml)
    doc = parser.parse
    doc.root.namespaces.default_prefix="ss"

    doc.find("//ss:workbook/ss:sheet").count

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

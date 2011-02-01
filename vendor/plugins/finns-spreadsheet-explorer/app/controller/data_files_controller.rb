
require 'simple-spreadsheet-extractor'

class DataFilesController < ApplicationController

  include SysMODB::SpreadsheetExtractor
  include SpreadsheetViewer

  def explore
    @data_file =  DataFile.find(params[:id])
    if ["xls","xlsx"].include?(mime_extension(@data_file.content_type))
      xml = spreadsheet_to_xml(open(@data_file.content_blob.filepath))
      @spreadsheet = parse_spreadsheet_xml(xml)
      respond_to do |format|
        format.html 
      end
    else
     respond_to do |format|
        flash[:error] = "Unable to view contents of this data file"
        format.html { redirect_to @data_file,:format=>"html" }
      end
    end
  end

end

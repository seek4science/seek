require 'seek/data/spreadsheet_explorer_representation'

module SpreadsheetHelper
  
  include Seek::Data::SpreadsheetExplorerRepresentation

  def generate_paginate_rows(rows, sheet_index, per_page)
    if sheet_index == params[:sheet].try(:to_i)
      current_page = params[:page].try(:to_i) || 1
    else
      current_page = 1
    end
    WillPaginate::Collection.create(current_page, per_page, rows.count) do |pager|
      start = (current_page-1)*per_page # assuming current_page is 1 based.
      pager.replace(rows[start, per_page])
    end
  end
end  
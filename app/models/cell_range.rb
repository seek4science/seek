#
# This extends the CellRange model defined in the finns-spreadsheet-explorer plugin.

require_dependency File.join(Rails.root, 'vendor', 'plugins', 'finns-spreadsheet-explorer', 'app', 'models', 'cell_range')

class CellRange < ActiveRecord::Base

  def reindexing_consequences
    [worksheet.content_blob.asset]
  end
  
end
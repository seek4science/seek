class Spreadsheet < ActiveRecord::Base
  
  belongs_to :data_file
  belongs_to :content_blob
  has_many :worksheets, :dependent => :destroy
  
  def update_metadata(workbook)
    worksheets.clear
    workbook.sheets.each do |sheet|
      worksheets << Worksheet.create(:last_row => sheet.last_row, :last_column => sheet.last_col)
    end
    self.save
  end
  
end

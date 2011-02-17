class SpreadsheetAnnotation < ActiveRecord::Base
  
  belongs_to :data_file
  
  belongs_to :source,
             :polymorphic => true
  
  def cell_coverage
    return to_alpha(start_column)+start_row.to_s + (end_column.nil? ? "" : ":" + to_alpha(end_column)+end_row.to_s)    
  end
  
private

  def to_alpha(col)
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(//)    
    result = ""
    col = col-1
    while (col > -1) do
      letter = (col % 26)
      result = alphabet[letter] + result
      col = (col / 26) - 1
    end
    result
  end
  
end
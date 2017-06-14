class CellRange < ActiveRecord::Base

  include Seek::Data::SpreadsheetExplorerRepresentation

  acts_as_annotatable :name_field=>:annotation

  belongs_to :worksheet

  #DONT HAVE ANY UPPER AND LOWER BOUNDS FOR CELLS - CAN CREATE ANNOTATIONS OUT OF RANGE

  validate :valid_cell_range
  validates_numericality_of :worksheet_id, :allow_nil => false, :only_integer => true, :greater_than_or_equal_to => 0

  attr_accessor :cell_range

  def reindexing_consequences
    [worksheet.content_blob.asset]
  end

  #Turns an Excel-style cell range (A1:B3) into two pairs of co-ordinates ((1,1),(2,3))
  def cell_range= range
    start_cell, end_cell = range.split(":")
    unless start_cell.nil? || start_cell.match(/^[a-zA-Z]+[1-9][0-9]*$/).nil?
      start_cell = start_cell.upcase
      self.start_column, self.start_row = from_alpha(start_cell.sub(/[0-9]+/,"")), start_cell.sub(/[A-Z]+/,"").to_i
      self.end_column, self.end_row = nil, nil
      if end_cell.nil?
        self.end_column = self.start_column
        self.end_row = self.start_row
      else
        end_cell = end_cell.upcase
        unless end_cell.match(/^[a-zA-Z]+[1-9][0-9]*$/).nil?
          self.end_column, self.end_row = from_alpha(end_cell.sub(/[0-9]+/,"")), end_cell.sub(/[A-Z]+/,"").to_i
        else
          start_row = nil
        end
      end
    else
      start_row = nil
    end
  end

  def cell_range
    return to_alpha(start_column)+start_row.to_s +
      ((end_column == start_column && end_row == start_row) ? "" : ":" + to_alpha(end_column)+end_row.to_s)
  end

private

  #If an invalid cell range was entered, one or more of the cell range co-ordinates will
  # be set to nil after cell_range= is called.
  def valid_cell_range
    if start_row.nil? || start_column.nil? || end_row.nil? || end_column.nil?
      errors[:base] << "Invalid cell range entered. Must be in the format of <b>A1</b> or <b>A1:B1</b>"
      return false
    elsif  !worksheet.nil? && (start_row < 1 || start_column < 1 || end_row > worksheet.last_row || end_column > worksheet.last_column)
      errors[:base] << "One or more cells between <b>#{to_alpha(start_column)}#{start_row}</b> and <b>#{to_alpha(end_column)}#{end_row}</b> are outside the worksheets range. Please select cells between <b>A1</b> and <b>#{to_alpha(worksheet.last_column)}#{worksheet.last_row}</b>"
      return false
    else
      return true
    end
  end


end

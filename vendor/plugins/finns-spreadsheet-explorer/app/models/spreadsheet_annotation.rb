class SpreadsheetAnnotation < ActiveRecord::Base

  unloadable
  
  include SpreadsheetUtil
  
  belongs_to :data_file
  
  belongs_to :source,
             :polymorphic => true
             
  acts_as_solr(:fields => [ :content ]) if Seek::Config.solr_enabled
  
  #DONT HAVE ANY UPPER AND LOWER BOUNDS FOR CELLS - CAN CREATE ANNOTATIONS OUT OF RANGE
               
  validates_presence_of :content
  #validates_presence_of :annotation_type
  validates_presence_of :source
  validates_presence_of :data_file
  validate :valid_cell_range
  validates_numericality_of :sheet, :allow_nil => false, :only_integer => true, :greater_than_or_equal_to => 0
    
  attr_accessor :cell_range
  
  #Turns an Excel-style cell range (A1:B3) into two pairs of co-ordinates ((1,1),(2,3))
  def cell_range= range
    start_cell, end_cell = range.split(":")
    unless start_cell.nil? || start_cell.match(/[a-zA-Z]+[1-9][0-9]*/).nil?
      start_cell = start_cell.upcase
      self.start_column, self.start_row = from_alpha(start_cell.sub(/[0-9]+/,"")), start_cell.sub(/[A-Z]+/,"").to_i
      self.end_column, self.end_row = nil, nil
      if end_cell.nil?
        self.end_column = self.start_column
        self.end_row = self.start_row
      else
        end_cell = end_cell.upcase
        unless end_cell.match(/[a-zA-Z]+[1-9][0-9]*/).nil?
          self.end_column, self.end_row = from_alpha(end_cell.sub(/[0-9]+/,"")), end_cell.sub(/[A-Z]+/,"").to_i
        end  
      end
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
      errors.add_to_base("Invalid cell range")
      return false
    end
  end
  
end
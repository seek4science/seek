class AnnotationTestController < ApplicationController

  def index

    cell = CellRange.new(:id => nil, :worksheet_id => 1, :start_row => 1, :start_column => 2, :end_row => 2, :end_column => 2 )

    if (cell.save)
      flash.now[:notice]="IT SAVED! ITS SAVED!"
    else
      flash.now[:notice]="It did not save so good"
    end

    cell = CellRange.find(1)
    annotations = cell.annotations
    flash.now[:notice]="Annotation iiiiis#{annotations}"
    #annotation = Annotation.new(:attribute_name => "Field Description",
    #                           :value => "My First Annotation",
    #                           :source_type => "Kangaroo",
    #                           :source_id => current_user.id,
    #                           :annotatable_type => cell.class.name,
    #                           :annotatable_id => cell.id)

    #annotation = Annotation.new(:attribute_name => nil,:value => "my first annotation",:source_type => "User",:source_id => 1,:annotatable_type => CellRange.class.name,:annotatable_id => cell.id)
   #{annotation.Class.name}"

  end
end


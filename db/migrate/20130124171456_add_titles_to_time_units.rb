class AddTitlesToTimeUnits < ActiveRecord::Migration
  class Unit < ActiveRecord::Base
  end

  TITLES_FOR_SYM = {"s"=>"second","min"=>"minute","h"=>"hour","d"=>"day","wk"=>"week","mo"=>"month","yr"=>"year"}

  def self.up
    Unit.where({:comment=>"time",:title=>nil}).each do |unit|
      title = TITLES_FOR_SYM[unit.symbol]
      unless title.nil?
        unit.title = title
        unit.save
      end
    end


  end

  def self.down
    Unit.where({:comment=>"time"}).each do |unit|
      unit.title=nil
      unit.save
    end
  end
end

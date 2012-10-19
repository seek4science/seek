class AssigningHourUnitToExistingSamples < ActiveRecord::Migration
  class Unit < ActiveRecord::Base
  end
  class Sample < ActiveRecord::Base
    belongs_to :age_at_sampling_unit, :class_name => 'AssigningHourUnitToExistingSamples::Unit', :foreign_key => "age_at_sampling_unit_id"
  end

  def self.up
    #assign hour unit to samples which have age_at_sampling
    hour_unit_id = Unit.find_by_symbol('h').try(:id)
    unless hour_unit_id.nil?
      Sample.all.select{|s| !s.age_at_sampling.blank? && s.age_at_sampling_unit_id.blank?}.each do |s|
         s.age_at_sampling_unit_id = hour_unit_id
         disable_authorization_checks{s.save}
      end
    end
  end

  def self.down
    Sample.all.select{|s| !s.age_at_sampling.blank? && !s.age_at_sampling_unit_id.blank?}.each do |s|
      s.age_at_sampling_unit_id = nil
      disable_authorization_checks{s.save}
    end
  end
end

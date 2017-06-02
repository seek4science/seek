class FixStrainAndOrganismFirstLetters < ActiveRecord::Migration
  def up
    Organism.find_each do |organism|
      organism.update_first_letter
      organism.update_column(:first_letter, organism.first_letter)
    end

    Strain.find_each do |strain|
      strain.update_first_letter
      strain.update_column(:first_letter, strain.first_letter)
    end
  end

  def down; end
end

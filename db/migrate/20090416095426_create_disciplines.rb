class CreateDisciplines < ActiveRecord::Migration
  def self.up
    create_table :disciplines do |t|
      t.string :title
      t.timestamps
    end
    d = Discipline.new(:title=>"Modeller")
    d.save!

    d = Discipline.new(:title=>"Experimentalist")
    d.save!

    d = Discipline.new(:title=>"Bioinformatician")
    d.save!
  end

  def self.down
    drop_table :disciplines
  end
end

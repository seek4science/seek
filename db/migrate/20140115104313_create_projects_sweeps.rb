class CreateProjectsSweeps < ActiveRecord::Migration
  def change
    create_table :projects_sweeps do |t|
      t.references :sweep
      t.references :project
    end
  end
end

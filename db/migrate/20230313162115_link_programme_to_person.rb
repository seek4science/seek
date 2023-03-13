class LinkProgrammeToPerson < ActiveRecord::Migration[6.1]
  def change

    # add_column :work_groups, :programme_id, :integer

    # add_column :group_memberships, :programme_id, :integer

    create_table :people_programmes, id: false do |t|
      t.belongs_to :person
      t.belongs_to :programme
    end
    add_column :programmes, :person_id, :integer
    add_column :people, :programme_id, :integer

    change_table :work_groups do |t|
      t.belongs_to :programme
    end

  end
end

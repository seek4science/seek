SUBSCRIBABLE_TABLES = %w(events samples specimens data_files models publications sops investigations studies assays)
class Project < ActiveRecord::Base
end

class WorkGroup < ActiveRecord::Base
  belongs_to :project
end

class GroupMembership < ActiveRecord::Base
  belongs_to :work_group
end

class ProjectSubscription < ActiveRecord::Base
  belongs_to :project
  belongs_to :person
end

class Subscription < ActiveRecord::Base
  belongs_to :person
end

class Person < ActiveRecord::Base
  has_many :project_subscriptions
  has_many :subscriptions
  has_many :group_memberships
  has_many :work_groups, :through => :group_memberships

  def projects
    work_groups.map(&:project).uniq
  end

  def set_default_subscriptions
    projects.uniq.each do |p|
      project_subscriptions.create :project => p unless project_subscriptions.map(&:project).include? p
      SUBSCRIBABLE_TABLES.each do |table|
        CreateSubscriptionTables.asset_ids(p, table).each do |asset_id|
          subscriptions.create :subscribable_type => table.classify, :subscribable_id => asset_id unless subscriptions.map {|s| [s.subscribable_type, s.subscribable_type]}.include? [asset_id, table.classify]
        end
      end
    end
  end
end

class CreateSubscriptionTables < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :person_id
      t.integer :subscribable_id
      t.string :subscribable_type
      t.string :subscription_type
      t.timestamps

    end

    create_table :project_subscriptions do |t|
      t.integer :person_id
      t.integer :project_id
      t.string :unsubscribed_types
      t.string :frequency
    end

    Person.all.each { |p| p.set_default_subscriptions }
  end

  def self.down
    drop_table :subscriptions
    drop_table :project_subscriptions
  end

  def self.asset_ids(project, table)
    case table
      when "assays"
        select_values <<-SQL
         SELECT #{table}.id FROM assays
         INNER JOIN studies ON assays.study_id=studies.id
         INNER JOIN investigations ON studies.investigation_id=investigations.id
          WHERE investigations.project_id=#{project.id}
        SQL
      when "studies"
        select_values <<-SQL
          SELECT #{table}.id FROM studies
          INNER JOIN investigations ON studies.investigation_id=investigations.id
          WHERE investigations.project_id=#{project.id}
        SQL
      else
        select_values <<-SQL
        SELECT #{table}.id FROM #{table}
        WHERE #{table}.project_id = #{project.id}
      SQL
    end
  end
end

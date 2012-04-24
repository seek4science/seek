module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}",:after_add=>:update_auth,:after_remove=>:update_auth
    end
  end

  def update_auth(project)
    AuthLookupUpdateJob.add_item_to_queue self
  end
end
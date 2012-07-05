module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}", :before_add => proc {|item, project| item.set_default_subscriptions [project] if item.subscribable?},
                              :before_remove => proc{|item, project| item.remove_subscriptions [project] if item.subscribable?}
    end
  end
end
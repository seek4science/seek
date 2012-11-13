module ProjectCompat
  def self.included(klass)
    klass.class_eval do
      join_table_name = [table_name, 'projects'].sort.join('_')
      has_and_belongs_to_many :projects, :join_table => "#{join_table_name}"

      def projects_and_ancestors
          self.projects.collect { |proj| [proj]+proj.ancestors }.flatten.uniq
      end
    end
  end
end
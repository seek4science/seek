module OnlyWritesUnique
  def concat *args
    if @reflection.options[:unique]
      load_target
      args = flatten_deeper(args).reject {|record| target.include? record}.uniq
    end
    super(*args)
  end

  def self.included base
    base.class_eval do
      alias_method :<<, :concat
      alias_method :push, :concat
    end
  end
end

ActiveRecord::Associations::AssociationCollection.class_eval do
  prepend OnlyWritesUnique
end

ActiveRecord::Associations::ClassMethods.valid_keys_for_has_many_association << :unique
ActiveRecord::Associations::ClassMethods.valid_keys_for_has_and_belongs_to_many_association << :unique

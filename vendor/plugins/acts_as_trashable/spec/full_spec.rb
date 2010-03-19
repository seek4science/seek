require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ActsAsTrashable Full Test" do
  
  before(:all) do
    ActiveRecord::Migration.suppress_messages do
      class TrashableTestSubThing < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:trashable_test_sub_things) do |t|
          t.column :name, :string
          t.column :trashable_test_many_thing_id, :integer
        end unless table_exists?
      end
  
      class TrashableTestManyThing < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:trashable_test_many_things) do |t|
          t.column :name, :string
          t.column :trashable_test_model_id, :integer
        end unless table_exists?
      
        has_many :sub_things, :class_name => 'TrashableTestSubThing', :dependent => :destroy
      end
  
      class TrashableTestManyOtherThing < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:trashable_test_many_other_things) do |t|
          t.column :name, :string
          t.column :trashable_test_model_id, :integer
        end unless table_exists?
      end
  
      class TrashableTestOneThing < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:trashable_test_one_things) do |t|
          t.column :name, :string
          t.column :trashable_test_model_id, :integer
        end unless table_exists?
      end
  
      class NonTrashableTestModel < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:non_trashable_test_models) do |t|
          t.column :name, :string
        end unless table_exists?
      end
      
      class NonTrashableTestModelsTrashableTestModel < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:non_trashable_test_models_trashable_test_models, :id => false) do |t|
          t.column :non_trashable_test_model_id, :integer
          t.column :trashable_test_model_id, :integer
        end unless table_exists?
      end
  
      class TrashableTestModel < ActiveRecord::Base
        ActiveRecord::Migration.create_table(:trashable_test_models) do |t|
          t.column :name, :string
          t.column :secret, :integer
        end unless table_exists?
      
        has_many :many_things, :class_name => 'TrashableTestManyThing', :dependent => :destroy
        has_many :many_other_things, :class_name => 'TrashableTestManyOtherThing'
        has_one :one_thing, :class_name => 'TrashableTestOneThing', :dependent => :destroy
        has_and_belongs_to_many :non_trashable_test_models
    
        attr_protected :secret
        
        acts_as_trashable
        
        def set_secret (val)
          self.secret = val
        end
        
        private
        
        def secret= (val)
          self[:secret] = val
        end
      end
      
      module ActsAsTrashable
        class TrashableNamespaceModel < ActiveRecord::Base
          ActiveRecord::Migration.create_table(:trashable_namespace_models) do |t|
            t.column :name, :string
            t.column :type_name, :string
          end unless table_exists?
          
          set_inheritance_column :type_name
          acts_as_trashable
        end
        
        class TrashableSubclassModel < TrashableNamespaceModel
        end
      end
    end
  end
  
  after(:all) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.drop_table(:trashable_test_models) if TrashableTestModel.table_exists?
      ActiveRecord::Migration.drop_table(:trashable_test_many_things) if TrashableTestManyThing.table_exists?
      ActiveRecord::Migration.drop_table(:trashable_test_many_other_things) if TrashableTestManyOtherThing.table_exists?
      ActiveRecord::Migration.drop_table(:trashable_test_sub_things) if TrashableTestSubThing.table_exists?
      ActiveRecord::Migration.drop_table(:trashable_test_one_things) if TrashableTestOneThing.table_exists?
      ActiveRecord::Migration.drop_table(:non_trashable_test_models_trashable_test_models) if NonTrashableTestModelsTrashableTestModel.table_exists?
      ActiveRecord::Migration.drop_table(:non_trashable_test_models) if NonTrashableTestModel.table_exists?
      ActiveRecord::Migration.drop_table(:trashable_namespace_models) if ActsAsTrashable::TrashableNamespaceModel.table_exists?
    end
  end
  
  before(:each) do
    TrashableTestModel.delete_all
    TrashableTestManyThing.delete_all
    TrashableTestManyOtherThing.delete_all
    TrashableTestSubThing.delete_all
    TrashableTestOneThing.delete_all
    NonTrashableTestModelsTrashableTestModel.delete_all
    NonTrashableTestModel.delete_all
    TrashRecord.delete_all
    ActsAsTrashable::TrashableNamespaceModel.delete_all
  end

  it "should be able to trash a record and restore without associations" do
    model = TrashableTestModel.new
    model.name = 'test'
    model.secret = 123
    model.save!
    TrashRecord.count.should == 0
    
    model.destroy
    TrashRecord.count.should == 1
    TrashableTestModel.count.should == 0
    
    restored = TrashableTestModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    restored.secret.should == 123
    TrashRecord.count.should == 0
    TrashableTestModel.count.should == 1
  end
  
  it "should be able to disable trash behavior" do
    model = TrashableTestModel.new
    model.name = 'test'
    model.save!
    TrashRecord.count.should == 0
    
    model.disable_trash do
      model.destroy
    end
    TrashRecord.count.should == 0
    TrashableTestModel.count.should == 0
  end
  
  it "should be able to trash a record and restore it with has_many associations" do
    many_thing_1 = TrashableTestManyThing.new(:name => 'many_thing_1')
    many_thing_1.sub_things.build(:name => 'sub_thing_1')
    many_thing_1.sub_things.build(:name => 'sub_thing_2')
    
    model = TrashableTestModel.new(:name => 'test')
    model.many_things << many_thing_1
    model.many_things.build(:name => 'many_thing_2')
    model.many_other_things.build(:name => 'many_other_thing_1')
    model.many_other_things.build(:name => 'many_other_thing_2')
    model.save!
    model.reload
    TrashableTestManyThing.count.should == 2
    TrashableTestSubThing.count.should == 2
    TrashableTestManyOtherThing.count.should == 2
    TrashRecord.count.should == 0
    
    model.destroy
    TrashRecord.count.should == 1
    TrashableTestModel.count.should == 0
    TrashableTestManyThing.count.should == 0
    TrashableTestSubThing.count.should == 0
    TrashableTestManyOtherThing.count.should == 2
    
    restored = TrashableTestModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    restored.many_things.collect{|t| t.name}.sort.should == ['many_thing_1', 'many_thing_2']
    restored.many_things.detect{|t| t.name == 'many_thing_1'}.sub_things.collect{|t| t.name}.sort.should == ['sub_thing_1', 'sub_thing_2']
    restored.many_other_things.collect{|t| t.name}.sort.should == ['many_other_thing_1', 'many_other_thing_2']
    TrashRecord.count.should == 0
    TrashableTestModel.count.should == 1
    TrashableTestManyThing.count.should == 2
    TrashableTestSubThing.count.should == 2
    TrashableTestManyOtherThing.count.should == 2
  end
  
  it "should be able to trash a record and restore it with has_one associations" do
    model = TrashableTestModel.new(:name => 'test')
    model.build_one_thing(:name => 'other')
    model.save!
    TrashRecord.count.should == 0
    TrashableTestOneThing.count.should == 1
    
    model.destroy
    TrashRecord.count.should == 1
    TrashableTestModel.count.should == 0
    TrashableTestOneThing.count.should == 0
    
    restored = TrashableTestModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    restored.one_thing.name.should == 'other'
    restored.one_thing.id.should == model.one_thing.id
    TrashRecord.count.should == 0
    TrashableTestModel.count.should == 1
    TrashableTestOneThing.count.should == 1
  end
  
  it "should be able to trash a record and restore it with has_and_belongs_to_many associations" do
    other_1 = NonTrashableTestModel.create(:name => 'one')
    other_2 = NonTrashableTestModel.create(:name => 'two')
    model = TrashableTestModel.new(:name => 'test')
    model.non_trashable_test_models = [other_1, other_2]
    model.save!
    model.reload
    TrashRecord.count.should == 0
    NonTrashableTestModel.count.should == 2
    
    model.destroy
    TrashRecord.count.should == 1
    TrashableTestModel.count.should == 0
    NonTrashableTestModelsTrashableTestModel.count.should == 0
    
    restored = TrashableTestModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    restored.non_trashable_test_models.collect{|r| r.name}.sort.should == ['one', 'two']
    TrashRecord.count.should == 0
    TrashableTestModel.count.should == 1
    NonTrashableTestModelsTrashableTestModel.count.should == 2
  end
  
  it "should be able to trash a record and restore without associations" do
    model = ActsAsTrashable::TrashableNamespaceModel.new
    model.name = 'test'
    model.save!
    TrashRecord.count.should == 0
    
    model.destroy
    TrashRecord.count.should == 1
    ActsAsTrashable::TrashableNamespaceModel.count.should == 0
    
    restored = ActsAsTrashable::TrashableNamespaceModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    TrashRecord.count.should == 0
    ActsAsTrashable::TrashableNamespaceModel.count.should == 1
  end
  
  it "should be able to trash a record and restore without associations" do
    model = ActsAsTrashable::TrashableSubclassModel.new
    model.name = 'test'
    model.save!
    TrashRecord.count.should == 0
    
    model.destroy
    TrashRecord.count.should == 1
    ActsAsTrashable::TrashableSubclassModel.count.should == 0
    
    restored = ActsAsTrashable::TrashableSubclassModel.restore_trash!(model.id)
    restored.reload
    restored.name.should == 'test'
    TrashRecord.count.should == 0
    ActsAsTrashable::TrashableSubclassModel.count.should == 1
  end
  
end

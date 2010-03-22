require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'zlib'

describe "TrashRecord" do
  
  class TestTrashableRecord
    attr_accessor :attributes
    
    def initialize (attributes = {})
      @attributes = attributes
    end
    
    def self.reflections
      @reflections || {}
    end
    
    def self.reflections= (vals)
      @reflections = vals
    end
  
    def self.base_class
      self
    end
    
    def self.inheritance_column
      'type'
    end
    
    def id
      attributes['id']
    end
    
    def id= (val)
      attributes['id'] = val
    end
    
    def name= (val)
      attributes['name'] = val
    end
    
    def value= (val)
      attributes['value'] = val
    end
  end
  
  class TestTrashableAssociationRecord < TestTrashableRecord
    def self.reflections
      @reflections || {}
    end
    
    def self.reflections= (vals)
      @reflections = vals
    end
  end
  
  class TestTrashableSubAssociationRecord < TestTrashableRecord
    def self.reflections
      @reflections || {}
    end
    
    def self.reflections= (vals)
      @reflections = vals
    end
  end
  
  before(:each) do
    TestTrashableRecord.reflections = nil
    TestTrashableAssociationRecord.reflections = nil
    TestTrashableSubAssociationRecord.reflections = nil
  end
  
  it "should serialize all the attributes of the original model" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => 5}
    original = TestTrashableRecord.new(attributes)
    trash = TrashRecord.new(original)
    trash.trashable_id.should == 1
    trash.trashable_type.should == "TestTrashableRecord"
    trash.trashable_attributes.should == attributes
  end
  
  it "should be backward compatible with uncompressed data" do
    attributes_1 = {'id' => 1, 'name' => 'trash', 'value' => 5}
    attributes_2 = {'id' => 2, 'name' => 'trash2', 'value' => 10}
    trash = TrashRecord.new(TestTrashableRecord.new({}))
    uncompressed = Marshal.dump(attributes_1)
    compressed = Zlib::Deflate.deflate(Marshal.dump(attributes_2))
    
    trash.data = uncompressed
    trash.trashable_attributes.should == attributes_1
    trash.data = compressed
    trash.trashable_attributes.should == attributes_2
  end
  
  it "should serialize all the attributes of has_many associations with :dependent => :destroy" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => Time.now}
    association_attributes_1 = {'id' => 2, 'name' => 'association_1'}
    association_attributes_2 = {'id' => 3, 'name' => 'association_2'}
    original = TestTrashableRecord.new(attributes)
    dependent_associations = [TestTrashableAssociationRecord.new(association_attributes_1), TestTrashableAssociationRecord.new(association_attributes_2)]
    dependent_associations_reflection = stub(:association, :name => :dependent_associations, :macro => :has_many, :options => {:dependent => :destroy})
    non_dependent_associations_reflection = stub(:association, :name => :non_dependent_associations, :macro => :has_many, :options => {})
    
    TestTrashableRecord.reflections = {:dependent_associations => dependent_associations_reflection, :non_dependent_associations => non_dependent_associations_reflection}
    original.should_not_receive(:non_dependent_associations)
    original.should_receive(:dependent_associations).and_return(dependent_associations)
    
    trash = TrashRecord.new(original)
    trash.trashable_attributes.should == attributes.merge(:dependent_associations => [association_attributes_1, association_attributes_2])
  end
  
  it "should serialize all the attributes of has_one associations with :dependent => :destroy" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => Date.today}
    association_attributes = {'id' => 2, 'name' => 'association_1'}
    original = TestTrashableRecord.new(attributes)
    dependent_association = TestTrashableAssociationRecord.new(association_attributes)
    dependent_association_reflection = stub(:association, :name => :dependent_association, :macro => :has_one, :options => {:dependent => :destroy})
    non_dependent_association_reflection = stub(:association, :name => :non_dependent_association, :macro => :has_one, :options => {})
    
    TestTrashableRecord.reflections = {:dependent_association => dependent_association_reflection, :non_dependent_association => non_dependent_association_reflection}
    original.should_not_receive(:non_dependent_association)
    original.should_receive(:dependent_association).and_return(dependent_association)
    
    trash = TrashRecord.new(original)
    trash.trashable_attributes.should == attributes.merge(:dependent_association => association_attributes)
  end
  
  it "should serialize all has_many_and_belongs_to_many associations" do
    attributes = {'id' => 1, 'name' => 'trash'}
    original = TestTrashableRecord.new(attributes)
    association_reflection = stub(:association, :name => :associations, :macro => :has_and_belongs_to_many)
    
    TestTrashableRecord.reflections = {:dependent_association => association_reflection}
    original.should_receive(:association_ids).and_return([2, 3, 4])
    
    trash = TrashRecord.new(original)
    trash.trashable_attributes.should == attributes.merge(:associations => [2, 3, 4])
  end
  
  it "should serialize associations with :dependent => :destroy of associations with :dependent => :destroy" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => Time.now}
    association_attributes_1 = {'id' => 2, 'name' => 'association_1'}
    association_attributes_2 = {'id' => 3, 'name' => 'association_2'}
    original = TestTrashableRecord.new(attributes)
    association_1 = TestTrashableAssociationRecord.new(association_attributes_1)
    association_2 = TestTrashableAssociationRecord.new(association_attributes_2)
    dependent_associations = [association_1, association_2]
    dependent_associations_reflection = stub(:association, :name => :dependent_associations, :macro => :has_many, :options => {:dependent => :destroy})
    sub_association_attributes = {'id' => 4, 'name' => 'sub_association_1'}
    sub_association = TestTrashableSubAssociationRecord.new(sub_association_attributes)
    sub_association_reflection = stub(:sub_association, :name => :sub_association, :macro => :has_one, :options => {:dependent => :destroy})
    
    TestTrashableRecord.reflections = {:dependent_associations => dependent_associations_reflection}
    TestTrashableAssociationRecord.reflections = {:sub_association => sub_association_reflection}
    original.should_receive(:dependent_associations).and_return(dependent_associations)
    association_1.should_receive(:sub_association).and_return(sub_association)
    association_2.should_receive(:sub_association).and_return(nil)
    
    trash = TrashRecord.new(original)
    trash.trashable_attributes.should == attributes.merge(:dependent_associations => [association_attributes_1.merge(:sub_association => sub_association_attributes), association_attributes_2])
  end
  
  it "should be able to restore the original model" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => 5}
    trash = TrashRecord.new(TestTrashableRecord.new(attributes))
    trash.data = Zlib::Deflate.deflate(Marshal.dump(attributes))
    restored = trash.restore
    restored.class.should == TestTrashableRecord
    restored.id.should == 1
    restored.attributes.should == attributes
  end
  
  it "should be able to restore associations" do
    restored = TestTrashableRecord.new
    attributes = {'id' => 1, 'name' => 'trash', 'value' => Time.now, :associations => {'id' => 2, 'value' => 'val'}}
    trash = TrashRecord.new(TestTrashableRecord.new)
    trash.data = Zlib::Deflate.deflate(Marshal.dump(attributes))
    associations_reflection = stub(:associations, :name => :associations, :macro => :has_many, :options => {:dependent => :destroy})
    TestTrashableRecord.reflections = {:associations => associations_reflection}
    TestTrashableRecord.should_receive(:new).and_return(restored)
    trash.should_receive(:restore_association).with(restored, :associations, {'id' => 2, 'value' => 'val'})
    restored = trash.restore
  end
  
  it "should be able to restore the has_many associations" do
    trash = TrashRecord.new(TestTrashableRecord.new)
    record = TestTrashableRecord.new
    
    associations_reflection = stub(:associations, :name => :associations, :macro => :has_many, :options => {:dependent => :destroy})
    TestTrashableRecord.reflections = {:associations => associations_reflection}
    associations = mock(:associations)
    record.should_receive(:associations).and_return(associations)
    associated_record = TestTrashableAssociationRecord.new
    associations.should_receive(:build).and_return(associated_record)
    
    trash.send(:restore_association, record, :associations, {'id' => 1, 'value' => 'val'})
    associated_record.id.should == 1
    associated_record.attributes.should == {'id' => 1, 'value' => 'val'}
  end
  
  it "should be able to restore the has_one associations" do
    trash = TrashRecord.new(TestTrashableRecord.new)
    record = TestTrashableRecord.new
    
    association_reflection = stub(:associations, :name => :association, :macro => :has_one, :klass => TestTrashableAssociationRecord, :options => {:dependent => :destroy})
    TestTrashableRecord.reflections = {:association => association_reflection}
    associated_record = TestTrashableAssociationRecord.new
    TestTrashableAssociationRecord.should_receive(:new).and_return(associated_record)
    record.should_receive(:association=).with(associated_record)
    
    trash.send(:restore_association, record, :association, {'id' => 1, 'value' => 'val'})
    associated_record.id.should == 1
    associated_record.attributes.should == {'id' => 1, 'value' => 'val'}
  end
  
  it "should be able to restore the has_and_belongs_to_many associations" do
    trash = TrashRecord.new(TestTrashableRecord.new)
    record = TestTrashableRecord.new
    
    associations_reflection = stub(:associations, :name => :associations, :macro => :has_and_belongs_to_many, :options => {})
    TestTrashableRecord.reflections = {:associations => associations_reflection}
    record.should_receive(:association_ids=).with([2, 3, 4])
    
    trash.send(:restore_association, record, :associations, [2, 3, 4])
  end
  
  it "should be able to restore associations of associations" do
    trash = TrashRecord.new(TestTrashableRecord.new)
    record = TestTrashableRecord.new
    
    associations_reflection = stub(:associations, :name => :associations, :macro => :has_many, :options => {:dependent => :destroy})
    TestTrashableRecord.reflections = {:associations => associations_reflection}
    associations = mock(:associations)
    record.should_receive(:associations).and_return(associations)
    associated_record = TestTrashableAssociationRecord.new
    associations.should_receive(:build).and_return(associated_record)

    sub_associated_record = TestTrashableSubAssociationRecord.new
    TestTrashableAssociationRecord.should_receive(:new).and_return(sub_associated_record)
    sub_association_reflection = stub(:sub_association, :name => :sub_association, :macro => :has_one, :klass => TestTrashableAssociationRecord, :options => {:dependent => :destroy})
    TestTrashableAssociationRecord.reflections = {:sub_association => sub_association_reflection}
    associated_record.should_receive(:sub_association=).with(sub_associated_record)
    
    trash.send(:restore_association, record, :associations, {'id' => 1, 'value' => 'val', :sub_association => {'id' => 2, 'value' => 'sub'}})
    associated_record.id.should == 1
    associated_record.attributes.should == {'id' => 1, 'value' => 'val'}
    sub_associated_record.id.should == 2
    sub_associated_record.attributes.should == {'id' => 2, 'value' => 'sub'}
  end
  
  it "should be able to restore original model and save it" do
    attributes = {'id' => 1, 'name' => 'trash', 'value' => 5}
    original = TestTrashableRecord.new(attributes)
    trash = TrashRecord.new(original)
    new_record = mock(:record)
    new_record.should_receive(:save!)
    trash.should_receive(:restore).and_return(new_record)
    trash.should_receive(:destroy)
    trash.restore!
  end
  
  it "should be able to empty the trash by max age" do
    max_age = mock(:max_age)
    time = 1.day.ago
    max_age.should_receive(:ago).and_return(time)
    TrashRecord.should_receive(:delete_all).with(['created_at <= ?', time])
    TrashRecord.empty_trash(max_age)
  end
  
  it "should be able to empty the trash for only certain types" do
    max_age = mock(:max_age)
    time = 1.day.ago
    max_age.should_receive(:ago).and_return(time)
    mock_class_1 = stub(:class_1, :base_class => stub(:base_class_1, :name => 'TypeOne'))
    mock_class_1.should_receive(:kind_of?).with(Class).and_return(true)
    mock_class_2 = 'TypeTwo'
    TrashRecord.should_receive(:delete_all).with(['created_at <= ? AND trashable_type IN (?, ?)', time, 'TypeOne', 'TypeTwo'])
    TrashRecord.empty_trash(max_age, :only => [mock_class_1, mock_class_2])
  end
  
  it "should be able to empty the trash for all except certain types" do
    max_age = mock(:max_age)
    time = 1.day.ago
    max_age.should_receive(:ago).and_return(time)
    TrashRecord.should_receive(:delete_all).with(['created_at <= ? AND trashable_type NOT IN (?)', time, 'TypeOne'])
    TrashRecord.empty_trash(max_age, :except => :type_one)
  end
  
  it "should be able to find a record by trashed type and id" do
    trash = TrashRecord.new(TestTrashableRecord.new(:name => 'name'))
    TrashRecord.should_receive(:find).with(:all, :conditions => {:trashable_type => 'TestTrashableRecord', :trashable_id => 1}).and_return([trash])
    TrashRecord.find_trash(TestTrashableRecord, 1).should == trash
  end
  
  it "should really save the trash record to the database and restore without any mocking" do
    TrashRecord.empty_trash(0)
    TrashRecord.count.should == 0
    
    attributes = {'id' => 1, 'name' => 'name value', 'value' => rand(1000000)}
    original = TestTrashableRecord.new(attributes)
    trash = TrashRecord.new(original)
    trash.save!
    TrashRecord.count.should == 1
    
    record = TrashRecord.find_trash(TestTrashableRecord, 1).restore
    record.class.should == TestTrashableRecord
    record.id.should == 1
    record.attributes.should == attributes
    
    TrashRecord.empty_trash(0, :except => TestTrashableRecord)
    TrashRecord.count.should == 1
    TrashRecord.empty_trash(0, :only => TestTrashableRecord)
    TrashRecord.count.should == 0
  end
  
end

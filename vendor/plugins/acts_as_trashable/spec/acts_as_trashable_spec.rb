require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../init.rb')

describe "ActsAsTrashable" do
  
  class TestTrashableModel
    include ActsAsTrashable
    
    def destroy
      really_destroy
    end
    
    def really_destroy
    end
    
    acts_as_trashable
  end
  
  it "should be able to inject trashable behavior onto ActiveRecord::Base" do
    ActiveRecord::Base.included_modules.should include(ActsAsTrashable)
  end
  
  it "should create a trash entry when a model is destroyed" do
    record = TestTrashableModel.new
    trash = mock(:trash)
    TrashRecord.should_receive(:transaction).and_yield
    TrashRecord.should_receive(:new).with(record).and_return(trash)
    trash.should_receive(:save!)
    record.should_receive(:really_destroy).and_return(:retval)
    record.destroy.should == :retval
  end
  
  it "should not create a trash entry when a model is destroyed inside a disable block" do
    record = TestTrashableModel.new
    TrashRecord.should_not_receive(:transaction)
    TrashRecord.should_not_receive(:new)
    record.should_receive(:really_destroy).and_return(:retval)
    record.disable_trash do
      record.destroy.should == :retval
    end
  end
  
  it "should be able to empty the trash based on age" do
    TrashRecord.should_receive(:empty_trash).with(1.day, :only => TestTrashableModel)
    TestTrashableModel.empty_trash(1.day)
  end
  
  it "should be able to restore a record by id" do
    trash = mock(:trash)
    record = mock(:record)
    TrashRecord.should_receive(:find_trash).with(TestTrashableModel, 1).and_return(trash)
    trash.should_receive(:restore).and_return(record)
    TestTrashableModel.restore_trash(1).should == record
  end
  
  it "should be able to restore a record by id and save it" do
    trash = mock(:trash)
    record = mock(:record)
    TrashRecord.should_receive(:find_trash).with(TestTrashableModel, 1).and_return(trash)
    trash.should_receive(:restore!).and_return(record)
    TestTrashableModel.restore_trash!(1).should == record
  end
  
end

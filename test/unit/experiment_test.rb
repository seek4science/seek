require "test_helper"

class ExperimentTest < ActiveSupport::TestCase

 test "validation" do
   ex = Factory :experiment,:title => "One"
   assert !Factory.build(:experiment,:title =>"One").save

   ex.date = nil
   assert !ex.valid?

   ex.reload
   ex.description = nil
   assert !ex.valid?

   ex.reload
   ex.sample = nil
   assert !ex.valid?

   ex.reload
   ex.contributor  = nil
   assert !ex.valid?

   ex.reload
   ex.project  = nil
   assert !ex.valid?

   ex.reload
   ex.institution  = nil
   assert !ex.valid?
 end
end
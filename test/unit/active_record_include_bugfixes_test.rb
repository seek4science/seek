require 'test_helper'
class ActiveRecordIncludeBugfixesTest < ActiveSupport::TestCase

  test "including the through association before including a has_many through association does not remove the source type restriction" do
    assert Assay.reflect_on_association(:sop_masters).options[:through] == :assay_assets
    assert Assay.reflect_on_association(:data_file_masters).options[:through] == :assay_assets
    assert Assay.reflect_on_association(:sop_masters).options[:source_type] == "Sop"
    assert Assay.reflect_on_association(:data_file_masters).options[:source_type] == "DataFile"

    Factory(:assay, :sop_masters => [Factory(:sop)], :data_file_masters => [Factory(:data_file)])

    assays = Assay.find(:all, :include => [:assay_assets, :sop_masters])

    assert assays.map(&:sop_masters).flatten.select {|sop_master| sop_master.class == DataFile}.empty?
    assert assays.first.assay_assets.loaded?
  end

  test "including a has_many :through association does not put nils into the target" do
    assert WorkGroup.reflect_on_association(:people).options[:through] == :group_memberships

    Factory(:work_group, :group_memberships => [Factory(:group_membership, :person => nil)]).id

    assert !WorkGroup.find(:all, :include => :people).map(&:people).flatten.include?(nil)

    #This assertion will only fail when StrategicEagerLoading is off, because otherwise you automatically include people
    assert WorkGroup.all.map(&:people).flatten.count == WorkGroup.find(:all, :include => :people).map(&:people).flatten.count

  end
end
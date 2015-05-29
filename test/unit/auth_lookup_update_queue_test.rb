require 'test_helper'

class AuthLookupUpdateQueueTest < ActiveSupport::TestCase

  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled=true
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled=@val
  end

  test "exists" do
    sop = Factory :sop
    model = Factory :model
    AuthLookupUpdateQueue.destroy_all
    assert !AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert !AuthLookupUpdateQueue.exists?(nil)

    disable_authorization_checks do
      AuthLookupUpdateQueue.create :item=>sop
    end

    assert AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert !AuthLookupUpdateQueue.exists?(nil)

    AuthLookupUpdateQueue.create :item=>nil

    assert AuthLookupUpdateQueue.exists?(sop)
    assert !AuthLookupUpdateQueue.exists?(model)
    assert AuthLookupUpdateQueue.exists?(nil)
  end

  test "updates to queue for sop" do
    user = Factory :user
    sop = nil
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sop = Factory :sop, :contributor=>user.person, :policy=>Factory(:private_policy)
    end
    assert_equal sop, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    sop.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sop.policy.save
    end
    assert_equal sop, AuthLookupUpdateQueue.last(:order=>:id).item
    AuthLookupUpdateQueue.destroy_all
    sop.title = Time.now.to_s
    assert_difference("AuthLookupUpdateQueue.count", 0) do
      disable_authorization_checks do
        sop.save!
      end
    end
  end

  test "updates to queue for assay" do
    user = Factory :user
    #otherwise a study and investigation are also created and triggers inserts to queue
    assay = Factory :assay, :contributor=>user.person, :policy=>Factory(:private_policy)
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      disable_authorization_checks do
        assay = Factory :assay, :contributor=>user.person, :policy=>Factory(:private_policy), :study=>assay.study
      end
    end
    assert_equal assay, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    assay.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      assay.policy.save
    end
    assert_equal assay, AuthLookupUpdateQueue.last(:order=>:id).item
    AuthLookupUpdateQueue.destroy_all
    assay.title = Time.now.to_s
    assert_no_difference("AuthLookupUpdateQueue.count") do
      disable_authorization_checks do
        assay.save!
      end
    end

  end

  test "updates to queue for study" do
    user = Factory :user
    #otherwise an investigation is also created and triggers inserts to queue
    study = Factory :study, :contributor=>user.person, :policy=>Factory(:private_policy)
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      study = Factory :study, :contributor=>user.person, :policy=>Factory(:private_policy), :investigation=>study.investigation
    end
    assert_equal study, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    study.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      study.policy.save
    end
    assert_equal study, AuthLookupUpdateQueue.last(:order=>:id).item
    AuthLookupUpdateQueue.destroy_all
    study.title = Time.now.to_s
    assert_no_difference("AuthLookupUpdateQueue.count") do
      disable_authorization_checks do
        study.save!
      end
    end
  end

  test "updates to queue for sample" do
    user = Factory :user
    #otherwise a specimen and strain are also created and triggers inserts to queue
    sample = Factory :sample, :contributor=>user.person, :policy=>Factory(:private_policy)
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sample = Factory :sample, :contributor=>user.person, :policy=>Factory(:private_policy), :specimen=>sample.specimen
    end
    assert_equal sample, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    sample.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sample.policy.save
    end
    assert_equal sample, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    sample.title = Time.now.to_s

    assert_no_difference("AuthLookupUpdateQueue.count") do
      disable_authorization_checks do
        sample.save!
      end
    end
  end

  test "updates to queue for specimen" do
    user = Factory :user
    #otherwise a strain is also created and triggers inserts to queue
    specimen = Factory :specimen, :contributor=>user.person, :policy=>Factory(:private_policy)
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      specimen = Factory :specimen, :contributor=>user.person, :policy=>Factory(:private_policy), :strain=>specimen.strain
    end
    assert_equal specimen, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    specimen.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      specimen.policy.save
    end
    assert_equal specimen, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    specimen.title = Time.now.to_s
    assert_no_difference("AuthLookupUpdateQueue.count") do
      disable_authorization_checks do
        specimen.save!
      end
    end
  end

  test "updates to queue for sweep" do
    user = Factory :user
    #otherwise a workflow is also created and triggers inserts to queue
    sweep = Factory :sweep, :contributor=>user.person, :policy=>Factory(:private_policy)
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sweep = Factory :sweep, :contributor=>user.person, :policy=>Factory(:private_policy), :workflow=>sweep.workflow
    end
    assert_equal sweep, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    sweep.policy.access_type = Policy::VISIBLE

    assert_difference("AuthLookupUpdateQueue.count", 1) do
      sweep.policy.save
    end
    assert_equal sweep, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    sweep.title = Time.now.to_s
    assert_no_difference("AuthLookupUpdateQueue.count") do
      disable_authorization_checks do
        sweep.save!
      end
    end
  end

  test "updates for remaining authorized assets" do
    user = Factory :user
    types = Seek::Util.authorized_types - [Sop, Assay, Sample, Specimen, Study,Sweep,TavernaPlayer::Run]
    types.each do |type|
      entity=nil
      assert_difference("AuthLookupUpdateQueue.count", 1, "unexpected count for created type #{type.name}") do
        entity = Factory type.name.underscore.to_sym, :contributor=>user.person, :policy=>Factory(:private_policy)
      end
      assert_equal entity, AuthLookupUpdateQueue.last(:order=>:id).item
      AuthLookupUpdateQueue.destroy_all
      entity.policy.access_type = Policy::VISIBLE

      assert_difference("AuthLookupUpdateQueue.count", 1) do
        entity.policy.save
      end
      assert_equal entity, AuthLookupUpdateQueue.last(:order=>:id).item
      AuthLookupUpdateQueue.destroy_all
      entity.title = Time.now.to_s
      assert_no_difference("AuthLookupUpdateQueue.count") do
        disable_authorization_checks do
          entity.save
        end
      end
    end
  end

  test "updates for person" do
    user = Factory :user
    person=nil
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      person = Factory :person, :user=>user
    end
    assert_equal person, AuthLookupUpdateQueue.last(:order=>:id).item

    AuthLookupUpdateQueue.destroy_all
    assert_difference("AuthLookupUpdateQueue.count", 1) do
      person.is_admin=true
      disable_authorization_checks do
        person.save!
      end
    end
    assert_equal person, AuthLookupUpdateQueue.last(:order=>:id).item
  end

  test "updates for group membership" do
    User.with_current_user(Factory(:admin)) do
      person = Factory :person
      person2 = Factory :person

      project = person.projects.first
      assert_equal [project],person.projects

      wg = Factory :work_group
      AuthLookupUpdateQueue.destroy_all
      assert_difference("AuthLookupUpdateQueue.count", 1) do
        gm = GroupMembership.create :person=>person, :work_group=>wg
        gm.save!
      end
      assert_equal person, AuthLookupUpdateQueue.last(:order=>:id).item

      AuthLookupUpdateQueue.destroy_all
      assert_difference("AuthLookupUpdateQueue.count", 2) do
        gm = person.group_memberships.first
        gm.person = person2
        gm.save!
      end

      assert_equal [person2,person], AuthLookupUpdateQueue.all(:order=>:id).collect{|a| a.item}
    end
  end

end

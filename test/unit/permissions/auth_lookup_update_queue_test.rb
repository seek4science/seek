require 'test_helper'

class AuthLookupUpdateQueueTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = true
    AuthLookupUpdateQueue.destroy_all
    Delayed::Job.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled = @val
  end

  test 'exists' do
    sop = Factory :sop
    model = Factory :model
    AuthLookupUpdateQueue.destroy_all
    assert !AuthLookupUpdateQueue.exists?(item: sop)
    assert !AuthLookupUpdateQueue.exists?(item: model)
    assert !AuthLookupUpdateQueue.exists?(item: nil)

    disable_authorization_checks do
      AuthLookupUpdateQueue.create item: sop
    end

    assert AuthLookupUpdateQueue.exists?(item: sop)
    assert !AuthLookupUpdateQueue.exists?(item: model)
    assert !AuthLookupUpdateQueue.exists?(item: nil)

    AuthLookupUpdateQueue.create item: nil

    assert AuthLookupUpdateQueue.exists?(item: sop)
    assert !AuthLookupUpdateQueue.exists?(item: model)
    assert AuthLookupUpdateQueue.exists?(item: nil)
  end

  test 'updates to queue for sop' do
    user = Factory :user
    sop = nil
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sop = Factory :sop, contributor: user.person, policy: Factory(:private_policy)
    end
    assert_equal sop, AuthLookupUpdateQueue.order(:id).last.item

    AuthLookupUpdateQueue.destroy_all
    sop.policy.access_type = Policy::VISIBLE

    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sop.policy.save
    end
    assert_equal sop, AuthLookupUpdateQueue.order(:id).last.item
    AuthLookupUpdateQueue.destroy_all
    sop.title = Time.now.to_s
    assert_difference('AuthLookupUpdateQueue.count', 0) do
      disable_authorization_checks do
        sop.save!
      end
    end
  end

  test 'updates to queue for assay' do
    user = Factory :user
    # otherwise a study and investigation are also created and triggers inserts to queue
    assay = Factory :assay, contributor: user.person, policy: Factory(:private_policy)
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      disable_authorization_checks do
        assay = Factory :assay, contributor: user.person, policy: Factory(:private_policy), study: assay.study
      end
    end
    assert_equal assay, AuthLookupUpdateQueue.order(:id).last.item

    AuthLookupUpdateQueue.destroy_all
    assay.policy.access_type = Policy::VISIBLE

    assert_difference('AuthLookupUpdateQueue.count', 1) do
      assay.policy.save
    end
    assert_equal assay, AuthLookupUpdateQueue.order(:id).last.item
    AuthLookupUpdateQueue.destroy_all
    assay.title = Time.now.to_s
    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        assay.save!
      end
    end
  end

  test 'updates to queue for study' do
    user = Factory :user
    # otherwise an investigation is also created and triggers inserts to queue
    study = Factory :study, contributor: user.person, policy: Factory(:private_policy)
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      study = Factory :study, contributor: user.person, policy: Factory(:private_policy), investigation: study.investigation
    end
    assert_equal study, AuthLookupUpdateQueue.order(:id).last.item

    AuthLookupUpdateQueue.destroy_all
    study.policy.access_type = Policy::VISIBLE

    assert_difference('AuthLookupUpdateQueue.count', 1) do
      study.policy.save
    end
    assert_equal study, AuthLookupUpdateQueue.order(:id).last.item
    AuthLookupUpdateQueue.destroy_all
    study.title = Time.now.to_s
    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        study.save!
      end
    end
  end

  test 'updates to queue for sample' do
    user = Factory :user
    sample = nil
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sample = Factory :sample, contributor: user.person, policy: Factory(:private_policy),
                       sample_type:Factory(:simple_sample_type,contributor:user.person)
    end
    assert_equal sample, AuthLookupUpdateQueue.order(:id).last.item

    AuthLookupUpdateQueue.destroy_all
    sample.policy.access_type = Policy::VISIBLE

    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sample.policy.save
    end
    assert_equal sample, AuthLookupUpdateQueue.order(:id).last.item
    AuthLookupUpdateQueue.destroy_all
    sample.title = Time.now.to_s
    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        sample.save!
      end
    end
  end

  test 'updates for remaining authorized assets' do
    user = Factory :user
    types = Seek::Util.authorized_types - [Sop, Assay, Study, Sample]
    types.each do |type|
      entity = nil
      assert_difference('AuthLookupUpdateQueue.count', 1, "unexpected count for created type #{type.name}") do
        entity = Factory type.name.underscore.to_sym, contributor: user.person, policy: Factory(:private_policy)
      end
      assert_equal entity, AuthLookupUpdateQueue.order(:id).last.item
      AuthLookupUpdateQueue.destroy_all
      entity.policy.access_type = Policy::VISIBLE

      assert_difference('AuthLookupUpdateQueue.count', 1) do
        entity.policy.save
      end
      assert_equal entity, AuthLookupUpdateQueue.order(:id).last.item
      AuthLookupUpdateQueue.destroy_all
      entity.title = Time.now.to_s
      assert_no_difference('AuthLookupUpdateQueue.count') do
        disable_authorization_checks do
          entity.save
        end
      end
    end
  end

  test 'updates when a user registers' do
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      user = Factory(:brand_new_user)
      assert_equal user, AuthLookupUpdateQueue.order(:id).last.item
    end
  end

  test "updates when a person's role changes" do
    person = Factory(:person)
    person.is_admin = false
    disable_authorization_checks { person.save! }

    AuthLookupUpdateQueue.destroy_all
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      person.is_admin = true
      disable_authorization_checks do
        person.save!
      end
    end
    assert_equal person, AuthLookupUpdateQueue.order(:id).last.item
  end

  test 'does not update when a user changes their password' do
    user = Factory(:user)

    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        user.update_attributes(password: '123456789', password_confirmation: '123456789')
      end
    end
  end

  test 'does not update when a person updates their profile' do
    person = Factory.create(:brand_new_person, user: Factory(:user))

    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        person.update_attributes(first_name: 'Dave')
      end
    end
  end

  test 'updates for group membership' do
    User.with_current_user(Factory(:admin)) do
      person = Factory :person
      person2 = Factory :person

      project = person.projects.first
      assert_equal [project], person.projects

      wg = Factory :work_group
      AuthLookupUpdateQueue.destroy_all
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        gm = GroupMembership.create person: person, work_group: wg
        gm.save!
      end
      assert_equal person, AuthLookupUpdateQueue.order(:id).last.item

      AuthLookupUpdateQueue.destroy_all
      assert_difference('AuthLookupUpdateQueue.count', 2) do
        gm = person.group_memberships.first
        gm.person = person2
        gm.save!
      end

      assert_equal [person2, person], AuthLookupUpdateQueue.order(:id).to_a.collect(&:item)
    end
  end

  test 'updates queue when creators added or removed' do
    creator = Factory(:person)
    person = Factory(:person)
    df = Factory(:data_file, contributor:person)
    User.with_current_user(person.user) do
      AuthLookupUpdateQueue.destroy_all

      df.creators << person
      assert_equal [person],df.creators

      assert_difference('AuthLookupUpdateQueue.count', 1) do
        df.save!
      end

      AuthLookupUpdateQueue.destroy_all

      df.creators = []
      assert_equal [],df.creators

      assert_difference('AuthLookupUpdateQueue.count', 1) do
        df.save!
      end
    end
  end

  test 'enqueue' do
    df = Factory(:data_file)
    df2 = Factory(:data_file)
    sop = Factory(:sop)
    sop2 = Factory(:sop)

    AuthLookupUpdateQueue.destroy_all

    assert_enqueued_with(job: AuthLookupUpdateJob) do
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        AuthLookupUpdateQueue.enqueue(df, priority: 2)
      end
    end

    assert_difference('AuthLookupUpdateQueue.count', 0, 'should not enqueue duplicate items') do
      entry = AuthLookupUpdateQueue.enqueue(df, priority: 3).first
      assert_equal 2, entry.priority, 'should not de-prioritize existing queue entry (lower priority executed first)'
    end

    assert_difference('AuthLookupUpdateQueue.count', 0, 'should not enqueue duplicate items') do
      entry = AuthLookupUpdateQueue.enqueue(df, priority: 1).first
      assert_equal 1, entry.priority, 'should change priority'
    end

    assert_no_enqueued_jobs do
      assert_difference('AuthLookupUpdateQueue.count', 1) do
        AuthLookupUpdateQueue.enqueue(df2, priority: 2, queue_job: false)
      end
    end

    # Handle flattening
    assert_enqueued_with(job: AuthLookupUpdateJob) do
      assert_difference('AuthLookupUpdateQueue.count', 2) do
        entries = AuthLookupUpdateQueue.enqueue([sop], [[[[sop2]]]], priority: 2).map(&:item)
        assert_includes entries, sop
        assert_includes entries, sop2
      end
    end
  end

  test 'dequeue' do
    df = Factory(:data_file)
    df2 = Factory(:data_file)
    df3 = Factory(:data_file)
    user = df.contributor.user

    AuthLookupUpdateQueue.destroy_all

    AuthLookupUpdateQueue.enqueue(df3, priority: 1)
    AuthLookupUpdateQueue.enqueue(df2, priority: 3)
    AuthLookupUpdateQueue.enqueue(user, df, priority: 2)

    assert_difference('AuthLookupUpdateQueue.count', -4) do
      items = AuthLookupUpdateQueue.dequeue(4)
      assert_equal [df3, df, user, df2], items, "should be ordered by priority, type, then ID"
    end

    FactoryGirl.create_list(:document, 10)
    with_config_value(:auth_lookup_update_batch_size, 6) do
      assert_equal 6, Seek::Config.auth_lookup_update_batch_size
      assert_difference('AuthLookupUpdateQueue.count', -Seek::Config.auth_lookup_update_batch_size,
                        "should dequeue by `Seek::Config.auth_lookup_update_batch_size` amount by default") do
        AuthLookupUpdateQueue.dequeue
      end
    end
  end
end

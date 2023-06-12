require 'test_helper'

class AuthLookupUpdateQueueTest < ActiveSupport::TestCase
  def setup
    @val = Seek::Config.auth_lookup_enabled
    Seek::Config.auth_lookup_enabled = true
    AuthLookupUpdateQueue.destroy_all
  end

  def teardown
    Seek::Config.auth_lookup_enabled = @val
  end

  test 'exists' do
    sop = FactoryBot.create :sop
    model = FactoryBot.create :model
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
    user = FactoryBot.create :user
    sop = nil
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sop = FactoryBot.create :sop, contributor: user.person, policy: FactoryBot.create(:private_policy)
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
    user = FactoryBot.create :user
    # otherwise a study and investigation are also created and triggers inserts to queue
    assay = FactoryBot.create :assay, contributor: user.person, policy: FactoryBot.create(:private_policy)
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      disable_authorization_checks do
        assay = FactoryBot.create :assay, contributor: user.person, policy: FactoryBot.create(:private_policy), study: assay.study
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
    user = FactoryBot.create :user
    # otherwise an investigation is also created and triggers inserts to queue
    study = FactoryBot.create :study, contributor: user.person, policy: FactoryBot.create(:private_policy)
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      study = FactoryBot.create :study, contributor: user.person, policy: FactoryBot.create(:private_policy), investigation: study.investigation
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
    user = FactoryBot.create :user
    sample = nil
    assert_difference('AuthLookupUpdateQueue.count', 1) do
      sample = FactoryBot.create :sample, contributor: user.person, policy: FactoryBot.create(:private_policy),
                       sample_type:FactoryBot.create(:simple_sample_type,contributor:user.person)
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
    user = FactoryBot.create :user
    types = Seek::Util.authorized_types - [Sop, Assay, Study, Sample]
    types.each do |type|
      entity = nil
      assert_difference('AuthLookupUpdateQueue.count', 1, "unexpected count for created type #{type.name}") do
        entity = FactoryBot.create type.name.underscore.to_sym, contributor: user.person, policy: FactoryBot.create(:private_policy)
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
      user = FactoryBot.create(:brand_new_user)
      assert_equal user, AuthLookupUpdateQueue.order(:id).last.item
    end
  end

  test "updates when a person's role changes" do
    person = FactoryBot.create(:person)
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
    user = FactoryBot.create(:user)

    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        user.update(password: '123456789', password_confirmation: '123456789')
      end
    end
  end

  test 'does not update when a person updates their profile' do
    person = FactoryBot.create(:brand_new_person, user: FactoryBot.create(:user))

    assert_no_difference('AuthLookupUpdateQueue.count') do
      disable_authorization_checks do
        person.update(first_name: 'Dave')
      end
    end
  end

  test 'updates for group membership' do
    User.with_current_user(FactoryBot.create(:admin)) do
      person = FactoryBot.create :person
      person2 = FactoryBot.create :person

      project = person.projects.first
      assert_equal [project], person.projects

      wg = FactoryBot.create :work_group
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
    creator = FactoryBot.create(:person)
    person = FactoryBot.create(:person)
    df = FactoryBot.create(:data_file, contributor:person)
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
    df = FactoryBot.create(:data_file)
    df2 = FactoryBot.create(:data_file)
    sop = FactoryBot.create(:sop)
    sop2 = FactoryBot.create(:sop)

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
    df = FactoryBot.create(:data_file)
    df2 = FactoryBot.create(:data_file)
    df3 = FactoryBot.create(:data_file)
    user = df.contributor.user

    AuthLookupUpdateQueue.destroy_all

    AuthLookupUpdateQueue.enqueue(df3, priority: 1)
    AuthLookupUpdateQueue.enqueue(df2, priority: 3)
    AuthLookupUpdateQueue.enqueue(user, df, priority: 2)

    assert_difference('AuthLookupUpdateQueue.count', -4) do
      items = AuthLookupUpdateQueue.dequeue(4)
      assert_equal [df3, df, user, df2], items, "should be ordered by priority, type, then ID"
    end

    FactoryBot.create_list(:document, 10)
    with_config_value(:auth_lookup_update_batch_size, 6) do
      assert_equal 6, Seek::Config.auth_lookup_update_batch_size
      assert_difference('AuthLookupUpdateQueue.count', -Seek::Config.auth_lookup_update_batch_size,
                        "should dequeue by `Seek::Config.auth_lookup_update_batch_size` amount by default") do
        AuthLookupUpdateQueue.dequeue
      end
    end
  end
end

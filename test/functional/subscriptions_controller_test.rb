require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'can subscribe to an asset' do
    person = Factory(:person)
    data_file = Factory(:subscribable)
    login_as(person)

    assert_empty person.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile')

    assert_difference('Subscription.count', 1) do
      post :create, subscription: { subscribable_id: data_file.id, subscribable_type: 'DataFile' }
    end

    assert_redirected_to data_file

    assert_not_empty person.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile')
  end

  test 'cannot subscribe someone else to an asset' do
    person = Factory(:person)
    someone_else = Factory(:person)
    data_file = Factory(:subscribable)
    login_as(person)

    assert_empty person.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile', person_id: someone_else.id)
    assert_empty someone_else.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile', person_id: someone_else.id)

    assert_difference('Subscription.count', 1) do
      post :create, subscription: { subscribable_id: data_file.id, subscribable_type: 'DataFile' }
    end

    assert_redirected_to data_file

    assert_not_empty person.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile')
    assert_empty someone_else.subscriptions.where(subscribable_id: data_file.id, subscribable_type: 'DataFile')
  end

  test 'can unsubscribe from an asset' do
    subscription = Factory(:subscription)
    person = subscription.person
    login_as(person)

    assert_difference('Subscription.count', -1) do
      delete :destroy, id: subscription.id
    end

    assert_redirected_to subscription.subscribable
  end

  test 'cannot unsubscribe someone else from an asset' do
    person = Factory(:person)
    subscription = Factory(:subscription)
    someone_else = subscription.person
    login_as(person)

    assert_not_equal someone_else, person

    assert_no_difference('Subscription.count') do
      delete :destroy, id: subscription.id
    end

    assert flash[:error].include?('not authorized')
  end
end

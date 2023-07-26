require 'test_helper'

class OauthApplicationTest < ActionDispatch::IntegrationTest
  def setup
    @read_application = FactoryBot.create(:oauth_application, scopes: 'read')
    @write_application = FactoryBot.create(:oauth_application, scopes: 'write')
    @person = FactoryBot.create(:admin)
    @document = FactoryBot.create(:private_document, contributor: @person)
    @user = @person.user
    @read_access_token = FactoryBot.create(:oauth_access_token, scopes: 'read', application: @read_application, resource_owner_id: @user.id)
    @write_access_token = FactoryBot.create(:oauth_access_token, scopes: 'write', application: @write_application, resource_owner_id: @user.id)
  end

  test 'should not allow read with no authentication' do
    get document_path(@document, format: :json)
    assert_response :forbidden
  end

  test 'should allow read with read scope' do
    get document_path(@document, format: :json), params: { access_token: @read_access_token.token }
    assert_response :success
  end

  test 'should implicitly allow read with write scope' do
    get document_path(@document, format: :json), params: { access_token: @write_access_token.token }
    assert_response :success
  end

  test 'should allow write with write scope' do
    put document_path(@document, format: :json), params: {
        data: {
            type: 'documents',
            id: @document.id,
            attributes: {
                description: 'changed the description'
            }
        },
        access_token: @write_access_token.token
    }

    assert_response :success
    assert_equal 'changed the description', @document.reload.description
  end

  test 'should not allow write with read scope' do
    put document_path(@document, format: :json), params: {
        data: {
            type: 'documents',
            id: @document.id,
            attributes: {
                description: 'changed the description'
            }
        },
        access_token: @read_access_token.token
    }

    assert_response :forbidden
    assert_not_equal 'changed the description', @document.reload.description
  end

  test 'should not allow access to non-API actions when a token is used' do
    get admin_path, params: { access_token: @write_access_token.token }

    assert_response :forbidden

    get all_tags_path, params: { access_token: @write_access_token.token }

    assert_response :forbidden
  end
end

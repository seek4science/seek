require 'test_helper'

class ModelsHelperTest < ActionView::TestCase

  test 'allow_model_comparison' do
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    assert_equal 1, model.version

    # only 1 version - refute
    refute allow_model_comparison(model.versions[0], model.latest_version)

    # 1 sbml and 1 non sbml - refute
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    disable_authorization_checks do
      model.save_as_new_version
      FactoryBot.create(:non_sbml_xml_content_blob, asset_version: model.version, asset: model)
    end
    model.reload
    refute allow_model_comparison(model.versions[0], model.latest_version)

    # 2 sbml - allow
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    disable_authorization_checks do
      model.save_as_new_version
      FactoryBot.create(:cronwright_model_content_blob, asset_version: model.version, asset: model)
    end
    model.reload
    assert allow_model_comparison(model.versions[0], model.versions.last)

    # 2 sbml, not downloadable - refute
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:publicly_viewable_policy))
    disable_authorization_checks do
      model.save_as_new_version
      FactoryBot.create(:cronwright_model_content_blob, asset_version: model.version, asset: model)
    end
    model.reload
    refute allow_model_comparison(model.versions[0], model.versions.last)

    # 2 sbml & 1 non-sbml, current sbml - allow
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    disable_authorization_checks do
      model.save_as_new_version
      FactoryBot.create(:cronwright_model_content_blob, asset_version: model.version, asset: model)
      model.save_as_new_version
      FactoryBot.create(:non_sbml_xml_content_blob, asset_version: model.version, asset: model)
    end
    model.reload
    assert allow_model_comparison(model.versions[0], model.versions[1])

    # 2 sbml & 1 non-sbml, current non-sbml - refute
    refute allow_model_comparison(model.versions[0], model.versions[2])

    # same version - refute
    refute allow_model_comparison(model.versions[2], model.versions[2])
  end
end

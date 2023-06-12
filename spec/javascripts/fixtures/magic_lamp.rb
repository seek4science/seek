# # Broken fixture
# MagicLamp.register_fixture(controller: SopsController, name: 'sops/with_associations') do
#   assay = FactoryBot.create(:assay, :policy => FactoryBot.create(:public_policy))
#   @sop = FactoryBot.create(:sop,
#                  :assays => [assay],
#                  :policy => FactoryBot.create(:public_policy))
#   @sop.valid?
#   @display_sop = @sop.latest_version
#   render :show
# end

MagicLamp.register_fixture(controller: SopsController, name: 'sops/new') do
  @controller_name = 'sops'
  @sop = Sop.new
  # Set the current_user
  User.current_user = FactoryBot.create(:user)
  session[:user_id] = User.current_user.id.to_s
  # Some URL helpers in the template don't work without this:
  request.env["action_dispatch.request.path_parameters"] = {
      action: "new",
      controller: "sops",
  }
  render :new
end

MagicLamp.register_fixture(controller: SopsController, name: 'sops/manage') do
  @sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor.user
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "manage",
      controller: "sops",
      id: @sop.id
  }
  render :manage
end

MagicLamp.register_fixture(name: 'sharing/form') do
  @sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor.user
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "edit",
      controller: "sops",
      id: @sop.id
  }
  render partial: 'sharing/form', locals: { object: @sop }
end


MagicLamp.register_fixture(name: 'projects-selector') do
  @sop = FactoryBot.create(:sop, policy: FactoryBot.create(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor.user
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "edit",
      controller: "sops",
      id: @sop.id
  }
  render partial: 'projects/project_selector', locals: { resource: @sop }
end

MagicLamp.register_fixture(name: 'project/markdown') do
  User.current_user = FactoryBot.create(:user)
  session[:user_id] = User.current_user.id.to_s

  @project = Project.create(title: 'markdown test',
    description: '# header

Some text

## second header

_italic **bold** text_

> Another paragraph')
  render "projects/show"
end
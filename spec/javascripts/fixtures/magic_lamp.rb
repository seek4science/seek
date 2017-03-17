MagicLamp.register_fixture(controller: SopsController, name: 'sops/with_associations') do
  assay = Factory(:assay, :policy => Factory(:public_policy))
  @sop = Factory(:sop,
                 :assays => [assay],
                 :policy => Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  render :show
end

MagicLamp.register_fixture(controller: SopsController, name: 'sops/new') do
  @controller_name = 'sops'
  @sop = Sop.new
  # Set the current_user
  User.current_user = Factory(:user)
  session[:user_id] = User.current_user.id.to_s
  # Some URL helpers in the template don't work without this:
  request.env["action_dispatch.request.path_parameters"] = {
      action: "new",
      controller: "sops",
  }
  render :new
end

MagicLamp.register_fixture(controller: SopsController, name: 'sops/edit') do
  @sop = Factory(:sop, policy: Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "edit",
      controller: "sops",
      id: @sop.id
  }
  render :edit
end

MagicLamp.register_fixture(name: 'sharing/form') do
  @sop = Factory(:sop, policy: Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "edit",
      controller: "sops",
      id: @sop.id
  }
  render partial: 'sharing/form', locals: { object: @sop }
end


MagicLamp.register_fixture(name: 'projects-selector') do
  @sop = Factory(:sop, policy: Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor
  session[:user_id] = User.current_user.id.to_s
  request.env["action_dispatch.request.path_parameters"] = {
      action: "edit",
      controller: "sops",
      id: @sop.id
  }
  render partial: 'projects/project_selector', locals: { resource: @sop }
end
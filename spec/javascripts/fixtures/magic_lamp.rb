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
  User.current_user = Factory(:user)
  session[:user_id] = User.current_user.id.to_s
  render :new
end

MagicLamp.register_fixture(controller: SopsController, name: 'sops/edit') do
  @sop = Factory(:sop, policy: Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  User.current_user = @sop.contributor
  render :edit
end

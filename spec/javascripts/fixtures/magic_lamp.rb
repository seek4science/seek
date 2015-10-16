MagicLamp.register_fixture(controller: SopsController, name: "sops/with_associations") do
  assay = Factory(:assay, :policy => Factory(:public_policy))
  @sop = Factory(:sop,
                 :assays => [assay],
                 :policy => Factory(:public_policy))
  @sop.valid?
  @display_sop = @sop.latest_version
  render :show
end
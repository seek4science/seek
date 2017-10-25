module Seek
  module Openbis

    class SeekUtil

      def createObisAssay(assay_params, creator, zample, sync_options)

        assay_params[:assay_class_id] ||= AssayClass.for_type("experimental").id
        assay_params[:title] ||= "OpenBIS #{zample.perm_id}"
        assay = Assay.new(assay_params)
        assay.contributor = creator
        obis_asset  = OpenbisExternalAsset.build(zample, sync_options)

        assay.external_asset = obis_asset

        assay
      end

      def createObisDataFile(obis_asset)

        dataset = obis_asset.content
        openbis_endpoint = obis_asset.seek_service

        df = DataFile.new(projects: [openbis_endpoint.project], title: "OpenBIS #{dataset.perm_id}",
                          license: openbis_endpoint.project.default_license)

        df.policy=openbis_endpoint.policy.deep_copy
        df.external_asset = obis_asset
        df
      end
    end
  end
end

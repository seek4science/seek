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
    end
  end
end

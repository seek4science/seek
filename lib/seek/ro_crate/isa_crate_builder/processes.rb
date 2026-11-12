module Seek
  module RoCrate
    class ISACrateBuilder
      # One LabProcess per assay linking its samples, data files and SOPs, and the SOPs as LabProtocols.
      module Processes
        private

        # The assay's run as a LabProcess: samples go in (object), data files and outgoing samples come
        # out (result), SOPs are the protocols. SEEK does not record which input produced which output,
        # so one process per assay states only what is known. Nil when the assay has none of the three.
        def process_reference(crate, assay, files)
          incoming, outgoing = samples_by_direction(assay)
          protocols = protocol_references(crate, assay)
          return if incoming.empty? && outgoing.empty? && files.empty? && protocols.empty?

          entity = ::ROCrate::ContextualEntity.new(crate, "#process-assay-#{assay.id}", '@type' => 'LabProcess')
          set(entity, process_properties(crate, assay, incoming, outgoing + files, protocols))
          crate.add_contextual_entity(entity).reference
        end

        def process_properties(crate, assay, inputs, outputs, protocols)
          { 'name' => "#{assay.title} process",
            'object' => sample_references(crate, inputs),
            'result' => outputs.map { |item| output_reference(crate, item) },
            'executesLabProtocol' => protocols,
            'agent' => creator_references(crate, assay) }
        end

        def output_reference(crate, item)
          item.is_a?(Sample) ? sample_entity(crate, item).reference : item.reference
        end

        # Viewable samples split into incoming and outgoing by the direction recorded on the assay
        # link; samples with no direction count as incoming.
        def samples_by_direction(assay)
          outgoing_ids = assay.assay_assets.outgoing.where(asset_type: 'Sample').pluck(:asset_id)
          viewable(assay.samples).partition { |sample| outgoing_ids.exclude?(sample.id) }
        end

        def protocol_references(crate, assay)
          viewable(assay.sops).map { |sop| protocol_entity(crate, sop).reference }
        end

        # One LabProtocol entity per SOP however many assays use it.
        def protocol_entity(crate, sop)
          @protocols ||= {}
          @protocols[sop.id] ||= begin
            entity = ::ROCrate::ContextualEntity.new(crate, "#protocol-#{sop.id}", '@type' => 'LabProtocol')
            set(entity, 'name' => sop.title,
                        'description' => sop.description,
                        'identifier' => sop.rdf_seek_id,
                        'url' => sop.rdf_seek_id,
                        'version' => sop.version)
            crate.add_contextual_entity(entity)
          end
        end
      end
    end
  end
end

# helper methods shared between OpenBIS related screens
module OpenbisHelper
  def can_browse_openbis?(project, user = User.current_user)
    Seek::Config.openbis_enabled && project.has_member?(user) && project.openbis_endpoints.any?
  end

  def modal_openbis_file_view(id)
    modal_options = { id: id, size: 'xl', 'data-role' => 'modal-openbis-file-view' }

    modal_title = 'DataSet Files'

    modal(modal_options) do
      modal_header(modal_title) +
        modal_body do
          content_tag(:div, '', id: :contents)
        end
    end
  end

  def disable_new_arrivals
    !Seek::Config.openbis_check_new_arrivals
  end

  def openbis_datafile_dataset(data_file)
    # render partial: 'data_files/openbis/dataset', locals: { dataset: dataset, data_file: data_file }
    dataset = data_file.openbis_dataset
    asset = data_file.external_asset
    render partial: 'openbis_datasets/openbis_dataset_panel',
           locals: { entity: dataset, modal_files: true, edit_button: true,
                     can_edit: data_file.can_edit?,
                     sync_at: asset.synchronized_at, err_msg: asset.err_msg }
  end

  def external_asset_details(seekobj)
    return 'No external asset'.html_safe unless seekobj.external_asset

    asset = seekobj.external_asset
    entity = asset.content

    if asset.is_a?(OpenbisExternalAsset)
      return render partial: 'openbis_common/openbis_entity_panel', object: entity,
                    locals: { can_edit: seekobj.can_edit?, edit_button: true,
                              sync_at: asset.synchronized_at, err_msg: asset.err_msg }
    end

    "Unsupported external asset #{seekobj.external_asset.class}".html_safe
  end

  def openbis_entity_edit_path(entity)
    if entity.is_a? Seek::Openbis::Zample
      return edit_openbis_endpoint_openbis_zample_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end
    if entity.is_a? Seek::Openbis::Dataset
      return edit_openbis_endpoint_openbis_dataset_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end
    if entity.is_a? Seek::Openbis::Experiment
      return edit_openbis_endpoint_openbis_experiment_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end

    'Unsupported'
  end

  def openbis_entity_sync_path(entity)
    if entity.is_a? Seek::Openbis::Zample
      return refresh_openbis_endpoint_openbis_zample_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end
    if entity.is_a? Seek::Openbis::Dataset
      return refresh_openbis_endpoint_openbis_dataset_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end
    if entity.is_a? Seek::Openbis::Experiment
      return refresh_openbis_endpoint_openbis_experiment_path openbis_endpoint_id: entity.openbis_endpoint, id: entity.perm_id
    end

    'Unsupported'
  end

  def openbis_files_modal_link(dataset)
    openbis_endpoint = dataset.openbis_endpoint
    file_count = dataset.dataset_file_count
    files_text = "#{file_count} File".pluralize(file_count)

    link_to(files_text, '#', class: 'view-files-link',
                             'data-toggle' => 'modal',
                             'data-target' => '#openbis-file-view',
                             'data-perm-id' => dataset.perm_id.to_s,
                             'data-endpoint-id' => openbis_endpoint.id.to_s)
  end

  # trims text content to a given limit, preserving the whole words.
  # it counts size over multiple calls, so trims the total text length not for each call
  class StatefulWordTrimmer
    attr_reader :trimmed

    def initialize(limit)
      @left = limit
      @trimmed = false
    end

    def trim(content)
      return '' if @trimmed || !content

      words = []
      content.split(/\s/).each do |w|
        if (@left - w.length) >= 0
          words << w unless w.empty?
          @left -= w.length
        else
          words << '...'
          @trimmed = true
          break
        end
      end
      words.join(' ')
    end
  end

  # thml sanitizer that trims htlm content to a given lenght. Once the total text legth reach limit
  # the content of followin html nodes is ignored. That way the display text is limited but no problem with
  # invalid not closed html tags
  class TextTrimmingScrubber < Loofah::Scrubber
    def initialize(limit)
      @direction = :top_down
      @trimmer = StatefulWordTrimmer.new(limit)
    end

    def scrub(node)
      if @trimmer.trimmed
        node.remove
        Loofah::Scrubber::STOP
      else
        node.content = @trimmer.trim(node.content) if node.text?
        node
      end
    end
  end

  # html sanitizer that removes styling elements
  class StylingScrubber < Loofah::Scrubber
    def initialize
      @direction = :top_down
      @style_attrs = %w[class style]
    end

    def scrub(node)
      node.attribute_nodes.each do |attr_node|
        attr_node.remove if @style_attrs.include? attr_node.node_name
      end
    end
  end

  def openbis_rich_content_sanitizer(content, max_length = nil)
    cleaned = Loofah.fragment(content).scrub!(StylingScrubber.new)
    cleaned = cleaned.scrub!(TextTrimmingScrubber.new(max_length)) if max_length
    cleaned = cleaned.scrub!(Seek::Openbis::ObisCommentScrubber.new)
    cleaned.scrub!(:prune).to_s.html_safe
  end
end

# frozen_string_literal: true

module SnapshotsHelper
  def list_item_snapshot_list(resource)
    content_tag :p, class: :list_item_attribute do
      content = content_tag(:b, 'Snapshots: ')
      content << if resource.snapshots.any?
                   resource.snapshots.collect do |snapshot|
                     snapshot_link(resource, snapshot)
                   end.join(', ').html_safe
                 else
                   content_tag(:span, 'No snapshots', class: :none_text)
                 end
    end
  end

  def snapshot_link(resource, snapshot)
    link_to snapshot_display_name(snapshot), polymorphic_path([resource, snapshot]), 'data-tooltip' => tooltip(snapshot.description)
  end

  def snapshot_display_name(snapshot)
    return snapshot.title if snapshot.title.present?
    return "Snapshot #{snapshot.snapshot_number}" if snapshot.persisted?
    "Snapshot #{snapshot.potential_snapshot_number}"
  end
end

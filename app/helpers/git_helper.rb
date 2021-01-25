module GitHelper
  def jstree_from_tree(tree, text = 'Root')
    nodes = [{
           id: 'repository-root',
           parent: '#',
           text: text,
           state: { opened: true }
         }]

    tree.walk_trees(:preorder) do |root, entry|
      nodes << {
        id: "#{root}#{entry[:name]}",
        parent: root.blank? ? 'repository-root' : root.chomp('/'),
        text: entry[:name]
      }
    end

    tree.walk_blobs(:preorder) do |root, entry|
      nodes << {
        id: "#{root}#{entry[:name]}",
        parent: root.blank? ? 'repository-root' : root.chomp('/'),
        text: entry[:name],
        icon: asset_path(icon_filename_for_key('markup'))
      }
    end

    nodes
  end

  def git_breadcrumbs(resource, path = nil)
    segments = (path || '').split("/")
    trees = segments[0..-2]

    content_tag(:nav) do
      content_tag(:ol, class: 'breadcrumb') do
        if path.nil?
          c = content_tag(:li, 'Root', class: 'breadcrumb-item active')
        else
          c = content_tag(:li, class: 'breadcrumb-item') do
            link_to('Root', polymorphic_path([resource, :git_tree]))
          end
        end
        trees.each_with_index do |tree, i|
          c += content_tag(:li, class: 'breadcrumb-item') do
            link_to(tree, polymorphic_path([resource, :git_tree], path: trees[0..i].join('/')))
          end
        end
        if segments.last
          c += content_tag(:li, segments.last, class: 'breadcrumb-item active')
        end
        c
      end
    end
  end

end
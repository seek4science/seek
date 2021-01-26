module GitHelper
  def jstree_from_tree(tree, root_text: 'Root', include_root: false)
    nodes = []
    root_id = '#'

    if include_root
      nodes << {
        id: '___repository-root',
        parent: '#',
        text: root_text,
        type: 'root',
        state: { opened: true }
      }
      root_id = '___repository-root'
    end

    ['tree', 'blob'].each do |type|
      tree.send("walk_#{type}s", :preorder) do |root, entry|
        nodes << {
          id: "#{root}#{entry[:name]}",
          parent: root.blank? ? root_id : root.chomp('/'),
          text: entry[:name],
          type: type
        }
      end
    end

    nodes
  end

  def git_path_input(modal_id, name, value, opts)
    select_trees = opts.delete(:select_trees) || false
    text_field_tag(name, value, opts.reverse_merge(data: { role: 'seek-git-path-input',
                                                           modal: modal_id,
                                                         'select-trees' => select_trees }))
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
module GitHelper
  def jstree_from_tree(tree, text = '', opts = {})
    h = {
        text: text,
        children: []
    }.merge(opts)

    tree.subtrees.each do |key, tree|
      h[:children] << jstree_from_tree(tree, key, { state: { opened: false } })
    end

    tree.blobs.each do |key, blob|
      h[:children] << { text: key, icon: asset_path(icon_filename_for_key('markup')) }
    end

    h
  end

  def git_breadcrumbs(version, path = nil)
    segments = (path || '').split("/")
    trees = segments[0..-2]

    content_tag(:nav) do
      content_tag(:ol, class: 'breadcrumb') do
        if path.nil?
          c = content_tag(:li, 'Root', class: 'breadcrumb-item active')
        else
          c = content_tag(:li, class: 'breadcrumb-item') do
            link_to('Root', git_tree_version_git_path(version))
          end
        end
        trees.each_with_index do |tree, i|
          c += content_tag(:li, class: 'breadcrumb-item') do
            link_to(tree, git_tree_version_git_path(version, path: trees[0..i].join('/')))
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
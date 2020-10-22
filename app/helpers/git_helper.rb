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
end
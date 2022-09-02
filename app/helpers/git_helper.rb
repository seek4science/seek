module GitHelper
  NAMESPACE = 'git-tree/'

  def jstree_json_from_git_tree(tree, root_text: 'Root', include_root: false)
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

    unless tree.nil?
      ['tree', 'blob'].each do |type|
        tree.send("walk_#{type}s", :preorder) do |root, entry|
          nodes << {
            id: "#{NAMESPACE}#{root}#{entry[:name]}",
            parent: root.blank? ? root_id : "#{NAMESPACE}#{root.chomp('/')}",
            text: entry[:name],
            type: type,
            data: { path: "#{root}#{entry[:name]}" }
          }
        end
      end
    end

    nodes
  end

  def json_from_git_annotations(git_annotations)
    h = {}

    git_annotations.each do |ga|
      path = "#{NAMESPACE}#{ga.path}"
      h[path] ||= []
      h[path] << {
          key: ga.key,
          label: t("git_annotation_label.#{ga.key}")
      }
    end

    h
  end

  def git_path_input(modal_id, name, value, opts)
    select_blobs = opts.delete(:select_blobs) || true
    select_trees = opts.delete(:select_trees) || false
    select_root = opts.delete(:select_root) || false
    text_field_tag(name, value, opts.reverse_merge(data: { role: 'seek-git-path-input',
                                                           modal: modal_id,
                                                           'select-blobs' => select_blobs,
                                                           'select-trees' => select_trees,
                                                           'select-root' => select_root }))
  end

  def git_breadcrumbs(resource, version, path = nil)
    segments = (path || '').split("/")
    trees = segments[0..-2]

    content_tag(:nav) do
      content_tag(:ol, class: 'breadcrumb') do
        if path.nil?
          c = content_tag(:li, 'Root', class: 'breadcrumb-item active')
        else
          c = content_tag(:li, class: 'breadcrumb-item') do
            link_to('Root', polymorphic_path([resource, :git_tree], version: version))
          end
        end
        trees.each_with_index do |tree, i|
          c += content_tag(:li, class: 'breadcrumb-item') do
            link_to(tree, polymorphic_path([resource, :git_tree], path: trees[0..i].join('/'), version: version))
          end
        end
        if segments.last
          c += content_tag(:li, segments.last, class: 'breadcrumb-item active')
        end
        c
      end
    end
  end

  def git_target_icon(ref)
    r = ref.sub('refs/', '')
    if r.start_with?('tags/')
      icon_tag('git_tag')
    elsif r.start_with?('remotes/origin/') || r.start_with?('heads/')
      icon_tag('git_branch')
    end
  end

  def is_image_path?(path)
    ext = path.split('/').last&.split('.')&.last&.downcase
    Seek::ContentTypeDetection::IMAGE_VIEWABLE_FORMAT.include?(ext)
  end

  def mutability_badge(git_version)
    content_tag(:span,
                git_version.mutable? ? 'Open' : 'Frozen',
                class: "mutability label #{git_version.mutable? ? 'label-warning' : 'label-success'}",
                title: git_version.mutable? ? 'This version is open and may change over time.' : 'This version is frozen and will not change.')
  end
end
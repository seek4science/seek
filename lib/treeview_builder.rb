class TreeviewBuilder
    include ImagesHelper
    include ActionView::Helpers::SanitizeHelper
    def initialize(project, folders)
    @project = project
    @folders = folders
    end

    def build_tree_data
        inv, std, prj, asy, assay_assets = Array.new(5) {[]}
        bold = { 'style': 'font-weight:bold' }
        @project.investigations.each do |investigation|
            investigation.studies.each do |study|
                next unless study.assays
                study.assays.each do |assay|
                    samples = assay.assets.select{|a| a.class == Sample}
                    assay_assets.push(create_node({text: "samples", 
                                        _type: "sample", 
                                        resource: samples[0], 
                                        count: samples.length })) if samples.length > 0
                    (assay.assets - samples).each do |asset|
                        assay_assets.push(create_node({text: asset.title, 
                                        _type: asset.class.name.underscore.downcase, 
                                        _id: asset.id, 
                                        resource: asset }))
                    end
                    asy.push(create_node({text: assay.title, 
                                        _type: 'assay', 
                                        _id: assay.id, 
                                        a_attr: bold, 
                                        children: assay_assets, 
                                        resource: assay}))
                    assay_assets = []
                end
                std.push(create_node({text: study.title,
                                        _type: 'study', 
                                        _id: study.id, 
                                        a_attr: bold, 
                                        label: asy.length>0 ? 'Assays' : nil, 
                                        children: asy, 
                                        resource: study}))
                asy = []
            end
            inv.push(create_node({text: investigation.title, 
                                        _type: 'investigation', 
                                        _id: investigation.id, 
                                        a_attr: bold, 
                                        label: 'Studies', 
                                        action: '#', 
                                        children: std, 
                                        resource: investigation}))
            std = []
        end
        
        # Documents folder
        @folders.reverse_each.map {|f| inv.unshift(folder_node(f))} if @folders.respond_to? :each
        
        prj.push(create_node({text: @project.title,
                                        _type: 'project',
                                        _id: @project.id,
                                        a_attr: bold, 
                                        label: 'Investigations',
                                        action: '#', 
                                        children: inv, 
                                        resource: @project}))

        sanitize(JSON[prj])
    end

    private

    def folder_node(folder)
        obj={id:"folder_#{folder.id}" ,text: folder.title,_type: 'folder',count: folder.count.to_s,
            children: folder.children.map { |child| folder_node(child) }, folder_id: folder.id,
            project_id: folder.project.id, resource: folder}
        create_node(obj)
    end

    def create_node(obj) 
        if(!obj[:resource].can_view?)
            obj[:text] = "hidden item"
            obj[:a_attr] = { 'style': 'font-style:italic;font-weight:bold;color:#ccc' }
            obj[:action] = nil
        end

        node = { id: obj[:id], text: obj[:text], a_attr: obj[:a_attr], count: obj[:count],
            data: { id:obj[:_id], type: obj[:_type], project_id: obj[:project_id], folder_id: obj[:folder_id]},
            state: { opened: true, separate: { label: obj[:label], action: obj[:action]}},
            children: obj[:children], icon: get_icon(obj[:resource]) }
        deep_compact(node)
    end

    def get_icon (resource)
        ActionController::Base.helpers.asset_path(resource_avatar_path(resource) ||
        icon_filename_for_key("#{resource.class.name.downcase}_avatar"))
    end

    def deep_compact(hash)
        hash.compact.transform_values do |value|
          next value unless value.class == Hash
          deep_compact(value)
        end.reject { |_k, v| v.blank? }
    end

end
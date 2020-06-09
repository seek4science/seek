
    class TreeviewBuilder
        def initialize(project, folders)
        @project = project
        @folders = folders
        end
    
        def build_tree_data
            inv, std, prj, asy = Array.new(4) { [] }
            bold = { 'style': 'font-weight:bold' }
            @project.investigations.each do |investigation|
                investigation.studies.each do |study|
                    next unless study.assays
                    study.assays.each_with_index do |assay, i|
                        asy.push(create_node({text: assay.title, _type: 'assay', _id: assay.id,
                             a_attr: bold, label: i.zero? && 'Assay'}))
                    end
                    std.push(create_node({text: study.title, _type: 'study', _id: study.id,
                         a_attr: bold, children: asy}))
                    asy = []
                end
                inv.push(create_node({text: investigation.title, _type: 'investigation',
                     _id: investigation.id, a_attr: bold, label: 'Studies', action: '#', children: std}))
                std = []
            end
            
            # Documents folder
            if @folders.respond_to? :each
                chld = @folders.reverse_each.map do |folder|
                    inv.unshift(folder_node(folder))
                end
            else
                chld = @folders
            end
           
            prj.push(create_node( {text: @project.title, _type: 'project', _id: @project.id,
                 a_attr: bold, label: 'Investigations', action: '#', children: inv}))

            JSON[prj]
        end

        def folder_node(folder)
            obj={id:"folder_#{folder.id}" ,text: folder.title,_type: 'folder',count: folder.count.to_s,
                children: folder.children.map { |child| folder_node(child) },
                folder_id: folder.id,project_id: folder.project.id}
            create_node(obj)
        end

        def create_node(obj) 
            obj[:opened] = true
            icon = ActionController::Base.helpers.asset_path("avatars/avatar-#{obj[:_type]}.png") unless icon!=nil
            nodes = {id:obj[:id], text: obj[:text], a_attr: obj[:a_attr], count: obj[:count], data: {id:obj[:_id],
                type:obj[:_type], project_id:obj[:project_id], folder_id:obj[:folder_id]},
                state: tidy_array(opened: obj[:opened], separate: tidy_array(label: obj[:label],
                action: obj[:action])), children: obj[:children], icon:icon }
            nodes.reject { |_k, v| v.nil? }
        end
    
        def tidy_array(arr)
            arr = arr.reject { |_k, v| v.nil? }
            arr == {} ? nil : arr
        end
    end

  
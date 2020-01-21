class TreeviewBuilder
  def initialize(project)
    @project = project
  end

  def build_tree_data
    inv, std, prj, asy = Array.new(4) { [] }
    bold = { 'style': 'font-weight:bold' }
    @project.investigations.each do |investigation|
      investigation.studies.each do |study|
        next unless study.assays

        study.assays.each_with_index do |assay, i|
          asy.push(create_node(assay.title, 'asy', nil, assay.id, bold, true, i.zero? ? 'Assay' : nil, nil,
                               [create_node('Methods', 'methods', method_count(study.id))]))
        end
        std.push(create_node(study.title, 'std', nil, study.id, bold, true, nil, nil, asy))
        asy = []
      end
      inv.push(create_node(investigation.title, 'inv', nil, investigation.id, bold, true, 'Studies', '#', std))
      std = []
    end
    # Documents folder
    chld = [create_node('Presentations', 'fld', f_count('Presentations')), create_node('Slideshows', 'fld', f_count('Slideshows')),
            create_node('Articles', 'fld', f_count('Articles')), create_node('Posters', 'fld', f_count('Posters'))]
    inv.unshift(create_node('Documents', nil, nil, nil, nil, true, nil, nil, chld))
    prj.push(create_node(@project.title, 'prj', nil, @project.id, bold, true, 'Investigations', '#', inv))
    JSON[prj]
  end

  def create_node(text, _type, count = nil, _id = nil, a_attr = nil, opened = true, label = nil, action = nil, children = nil)
    nodes = { text: text, _type: _type, _id: _id, a_attr: a_attr, count: count,
              state: tidy_array(opened: opened, separate: tidy_array(label: label, action: action)), children: children }
    nodes.reject { |_k, v| v.nil? }
  end

  def tidy_array(arr)
    arr = arr.reject { |_k, v| v.nil? }
    if arr == {}
      nil
    else
      arr
    end
  end

  def f_count(folder_name)
    folder_id = DefaultProjectFolder.where(title: folder_name).first.id
    (@project.other_project_files.select { |file| file.default_project_folders_id == folder_id }).length.to_s
  end

  def method_count(study_id)
    JSON.parse(StudyDesign.where(study_id: study_id).first.methods).count.to_s
  end
end

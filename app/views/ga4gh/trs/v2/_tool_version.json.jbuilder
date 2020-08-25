json.author workflow_version.creators.map(&:name)
json.name workflow_version.title
json.id workflow_version.version
json.descriptor_type case workflow_version.workflow_class&.key
                     when 'CWL'
                       'CWL'
                     when 'Nextflow'
                       'NFL'
                     when 'Galaxy'
                       'GALAXY'
                     else
                       nil
                     end

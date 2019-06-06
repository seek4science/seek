# -*- coding: utf-8 -*-


import sys
from galaxy_functions import *
   
    
### MAIN CODE

report_status("Script started")

# load json from first command argument
json_args = json.loads(sys.argv[1])
input_data = json_args['input_data']

gi = connect_to_galaxy(json_args['url'],  json_args['api_key'])
#connect to galaxy

library,  files,  investigation_folder = create_investigation_library(gi, 'FAIRDOM', json_args['folder_name'])
#add data - added to a Data Library named FAIRDOM. Write access is required to the library
   
report_status("Deploying data")
uploads = deploy_data(gi, library,  input_data, files,   json_args['folder_name'],  investigation_folder)

report_status("Setting up workflow")
invoked_workflow = invoke_workflow(gi, json_args['history_name'],  json_args['workflow_id'],  uploads)            

report_status("Workflow started",{"history_id" : invoked_workflow['history_id']})

wait_for_workflow(gi,  invoked_workflow)

report_status("Workflow complete")


report_status("Downloading data")

downloads = {
    'concat': {
        'name' : 'out_file1',
        'filename_postfix' : 'concat.txt' # zip file with a html (and other stuff) inside
    }
}

# downloads = {
#     'FastQC forward': {
#         'name' : 'html_file',
#         'filename_postfix' : 'fastqc_fw.zip' # zip file with a html (and other stuff) inside
#     },
#     'FastQC reverse' : {
#         'name' : 'text_file', # essentially same output as previous one, but text version
#         'filename_postfix' : 'fastqc_rev.txt'
#     },
#     'Salmon' : {
#         'name' : 'output_quant',
#         'filename_postfix' : 'counts.txt'
#     }
# }

download_data(gi,invoked_workflow, downloads)

report_status("Finished")
exit()






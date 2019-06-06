# -*- coding: utf-8 -*-

from bioblend import galaxy
import bioblend
import json
import time
import sys

def report_status(message, data = {}):
    r = {
        "status" : message,
        "data" : data
    }
    print(json.dumps(r))
    sys.stdout.flush() # make sure the message gets delivered rather than buffered

report_status("Script started")

# load json from first command argument
json_args = json.loads(sys.argv[1])
input_data = json_args['input_data']

json_args['investigation'] = 'Stuart script testing'
json_args['history_name'] = 'Stuart script testing history'


#connect to galaxy
gi = galaxy.GalaxyInstance(url=json_args['url'], key=json_args['api_key'])
gi.users.get_current_user() # just to check

#add data - added to a Data Library named FAIRDOM. Write access is required to the library
library = gi.libraries.get_libraries(name = 'FAIRDOM')

# If a folder with the investigation name already exist, 

root_folder = gi.libraries.get_folders(library[0]['id'])
files = gi.libraries.show_library(library[0]['id'], contents=True)

investigation_present = False

investigation_library = ""

for file in files:
    if file['name'] == ("/" + json_args['investigation']):
        investigation_present = True
        investigation_library = file['id']

if not investigation_present:    
    investigation_library =  gi.libraries.create_folder(library[0]['id'], json_args['investigation'], description=None)[0]
else:
    investigation_library =  gi.libraries.get_folders(library[0]['id'], name = "/" + json_args['investigation'])[0]    

report_status("Deploying data")

uploads = []
print(input_data)
for key, file in input_data.items():
        #print(file)
        # does not check if file is present
        file_present = False
        for avail_file in files:
            if avail_file['name'] == ("/" + json_args['investigation'] + "/" + file):                
                uploads.append(avail_file) 
                file_present = True
                break
        if not file_present :
            # this gives url as filename, can be changed through update, not yet implemented
            uploaded_file = gi.libraries.upload_file_from_url(library[0]['id'], 
                 file_url = file, 
                 folder_id=investigation_library['id'], 
                 file_type='fastqsanger.gz', 
                 #dbkey='?'
                )
            uploads.append(uploaded_file[0])

# to be improved, now waiting for all samples to be uploaded
not_yet_ready = True
errors = False
while not_yet_ready:            
    for upload in uploads:
        #print(gi.libraries.show_dataset(library[0]['id'], upload['id'])['state'])
        if gi.libraries.show_dataset(library[0]['id'], upload['id'])['state'] == 'ok':
            not_yet_ready = False
            # update_library_dataset(library[0]['id'], name="name_to_which_it_needs_to_be_changed")
        elif gi.libraries.show_dataset(library[0]['id'], upload['id'])['state'] == 'error':
            not_yet_ready = False
            errors = True
        else: 
            not_yet_ready = True

    if not_yet_ready:    
        report_status("Waiting for upload")
        time.sleep(60)
            

# run the workflow

#assumes a workflow with that name is present for the user
workflows = gi.workflows.get_workflows(workflow_id = json_args['workflow_id'], published=True)
workflow = workflows[0]

invoked_workflows = {}

report_status("Setting up workflow")

    
# assuming order forward - reverse and only for the first pair
inputs = {}
inputs[0] = { 'src':'ld', 'id':uploads[0]['id'] }
inputs[1] = { 'src':'ld', 'id':uploads[1]['id'] }

invoked_workflow = gi.workflows.invoke_workflow(workflow['id'], 
                         inputs=inputs, 
                         import_inputs_to_history=True, 
                         history_name=json_args['history_name'])
report_status("Workflow started",{"history_id" : invoked_workflow['history_id']})

# needs to match annotation of workflow step labels
# assuming downloading one file per step
downloads = {
    'FastQC forward': {
        'type' : 'html_file',
        'filename_postfix' : 'fastqc_fw.zip' # zip file with a html (and other stuff) inside
    }, 
    'FastQC reverse' : {
        'type' : 'text_file', # essentially same output as previous one, but text version
        'filename_postfix' : 'fastqc_rev.txt'
    }, 
    'Salmon' : {
        'type' : 'output_quant',
        'filename_postfix' : 'counts.txt'
    }
}

# wait until all the jobs have finished

all_ready = False
job_found = False

while not (all_ready and job_found):
    time.sleep(10)    
    filename_prefix = json_args['investigation'] + '_' + json_args['history_name'] + '_' # to do: link with sample name, for now hardcoded

    step_status = {'step_status' : {}}
    try:
        invocation = gi.workflows.show_invocation(invoked_workflow['workflow_id'], invoked_workflow['id'])
        all_ready = True
        job_found = False
        for step in invocation['steps']:
            if step['job_id']: # inputs have no job id
                job_found = True
                state = gi.jobs.get_state(step['job_id'])
                step_status['step_status'][step['job_id']] = state
                if state != 'ok':
                    all_ready = False
        report_status("Workflow running",step_status)
    except bioblend.ConnectionError as bioblend_error:
        print("Bioblend connection error")

report_status("Workflow complete")
exit()






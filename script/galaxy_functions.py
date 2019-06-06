### FUNCTIONS
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
    
def connect_to_galaxy(url,  api_key):    
    gi = galaxy.GalaxyInstance(url = url,  key = api_key)
    gi.users.get_current_user() # just to check
    return gi
    
def create_investigation_library(gi, libary_name,investigation_name ):    
    library = gi.libraries.get_libraries(name = libary_name)

    # If a folder with the investigation name already exist,     
    files = gi.libraries.show_library(library[0]['id'], contents=True)

    investigation_present = False

    investigation_folder = ""

    for file in files:
        if file['name'] == ("/" + investigation_name):
            investigation_present = True
            investigation_folder = file['id']

    if not investigation_present:    
        investigation_folder =  gi.libraries.create_folder(library[0]['id'], investigation_name, description=None)[0]
    else:
        investigation_folder =  gi.libraries.get_folders(library[0]['id'], name = "/" +investigation_name)[0] 
    return library,  files, investigation_folder    
    
def deploy_data(gi, library,  input_data,  files, investigation_folder_name,  investigation_folder):    
    uploads = []
    for key, file in input_data.items():
            #print(file)
            # does not check if file is present
            file_present = False
            for avail_file in files:
                if avail_file['name'] == ("/" +investigation_folder_name + "/" + file):                
                    uploads.append(avail_file) 
                    file_present = True
                    break
            if not file_present :
                # this gives url as filename, can be changed through update, not yet implemented
                uploaded_file = gi.libraries.upload_file_from_url(library[0]['id'], 
                     file_url = file, 
                     folder_id=investigation_folder['id'], 
                     file_type='fastqsanger.gz', 
                     #dbkey='?'
                    )
                uploads.append(uploaded_file[0])

    # to be improved, now waiting for all samples to be uploaded
    not_yet_ready = True
    errors = False
    while not_yet_ready:            
        for upload in uploads:            
            if gi.libraries.show_dataset(library[0]['id'], upload['id'])['state'] == 'ok':
                not_yet_ready = False                
            elif gi.libraries.show_dataset(library[0]['id'], upload['id'])['state'] == 'error':
                not_yet_ready = False
                errors = True
            else: 
                not_yet_ready = True

        if not_yet_ready:    
            report_status("Waiting for upload")
            time.sleep(60)
        return uploads


def invoke_workflow(gi,  history_name,  workflow_id,  uploads):
    #assumes a workflow with that name is present for the user
    workflows = gi.workflows.get_workflows(workflow_id = workflow_id, published=True)
    workflow = workflows[0]
        
    # assuming order forward - reverse and only for the first pair
    inputs = {}
    inputs[0] = { 'src':'ld', 'id':uploads[0]['id'] }
    inputs[1] = { 'src':'ld', 'id':uploads[1]['id'] }

    invoked_workflow = gi.workflows.invoke_workflow(workflow['id'], 
                             inputs=inputs, 
                             import_inputs_to_history=True, 
                             history_name=history_name)    
    return invoked_workflow
    
def wait_for_workflow(gi,  invoked_workflow):
    # wait until all the jobs have finished
    all_ready = False
    job_found = False

    while not (all_ready and job_found):
        time.sleep(10)            
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

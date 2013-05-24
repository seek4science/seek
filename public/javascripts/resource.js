function showResourceVersion(form) {
    var url=$('resource_versions').value;    
    location.href=url;
    form.submit;
}

// ***************  Resource Upload Validation  *****************

function validateResourceFields(is_new_file, resource_name, is_managed) {

    // only make this test if that's a new SOP
    if(is_new_file) {
        var respond_to_content_blobs = resource_name=='model' ? true :false;
        if (!validateUploadFormFields(respond_to_content_blobs, resource_name))
           return (false);
    }

    // other tests are applicable to both editing and creating new SOP
    if($(resource_name + '_title').value.length == 0) {
        alert("Please specify the title!");
        $(resource_name + '_title').focus();
        return(false);
    }
    if (is_managed){
        if (!checkProjectExists(resource_name)) {
            return (false);
        }

        // check if no tokens remain in the attributions autocompleter
        // (only do this if the fold with attributions is expanded)
        if($('attributions_fold_content').style.display == "block" &&
            autocompleters[attributions_autocompleter_id].getRecognizedSelectedIDs() != "")
            {
            alert('You didn\'t press "Add" link to add items in the attributions autocomplete field.');
            $('attributions_autocomplete_input').focus();
            return(false);
        }
/*        clickLink($('preview_permission'));*/
    }
/*    else{*/
        // filename and title set - can submit
        $(resource_name + '_submit_btn').disabled = true;
        $(resource_name + '_submit_btn').value = (is_new_file==true ? "Creating..." : "Updating...");
        $(resource_name + '_submit_btn').form.submit();
/*    }*/

}

function checkProjectExists(prefix) {
    el=prefix+"_project_ids";
    if ($F(el).length < 1) {
        alert("Please specify at least one project");
        return (false);       
    }
    return(true);
}

function createOrUpdateResource(is_new_file, resource_name){
    // filename and title set - can submit
    $(resource_name + '_submit_btn').disabled = true;
    $(resource_name + '_submit_btn').value = (is_new_file=='true' ? "Creating..." : "Updating...");
    $(resource_name + '_submit_btn').form.submit();

    RedBox.close();
}

function validateUploadFormFields(respond_to_content_blobs, resource_name) {
    if (respond_to_content_blobs) {
        if ($('pending_files').children.length == 0 && $(resource_name + "_image_image_file") == null) {
            alert("Please specify at least a file to upload or provide a URL.");
            return (false);
        } else if ($('pending_files').children.length == 0 && $(resource_name + "_image_image_file") != null && $(resource_name + "_image_image_file").value == '' && $('previous_version_image') == null) {
            alert("Please specify at least a file/image to upload or provide a URL.");
            return (false);
        }
    } else {
        if ($(resource_name + '_data').value.length == 0 && $(resource_name + '_data_url').value.length == 0) {
            alert("Please specify at least a file to upload or provide a URL.");
            $(resource_name + '_data').focus();
            return (false);
        }
    }
    return (true);
}

function validateUploadNewVersion(respond_to_content_blobs, resource_name){
    if (!validateUploadFormFields(respond_to_content_blobs, resource_name))
        return (false);
    $('new_version_submit_btn').disabled = true;
    $('new_version_submit_btn').value = "Uploading ...";
    $('new_version_submit_btn').form.submit();
    return (true);
}
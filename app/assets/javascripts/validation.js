// ***************  Resource Upload Validation  *****************

function validateResourceFields(isNewFile, resourceName) {
    // only make this test if that's a new SOP
    if (isNewFile) {
        var respond_to_content_blobs = resourceName === 'model';
        if (!validateUploadFormFields(respond_to_content_blobs, resourceName))
           return false;
    }

    // other tests are applicable to both editing and creating new SOP
    var title = $j('#' + resourceName + '_title');
    if (!title.val()) {
        alert("Please specify the title!");
        title.focus();
        return false;
    }

    // filename and title set - can submit
    var submitBtn = $j('#' + resourceName + '_submit_btn')[0];
    submitBtn.disabled = true;
    submitBtn.value = isNewFile ? "Creating..." : "Updating...";
    submitBtn.form.submit();
}

function createOrUpdateResource(is_new_file, resource_name){
    // filename and title set - can submit
    $(resource_name + '_submit_btn').disabled = true;
    $(resource_name + '_submit_btn').value = (is_new_file=='true' ? "Creating..." : "Updating...");
    $(resource_name + '_submit_btn').form.submit();
}

function validateUploadFormFields(respond_to_content_blobs, resource_name) {
    if (respond_to_content_blobs) {
        if ($('pending-files').children.length == 0 && $(resource_name + "_image_image_file") == null) {
            alert("Please specify at least a file to upload or provide a URL.");
            return false;
        } else if ($('pending-files').children.length == 0 && $(resource_name + "_image_image_file") != null && $(resource_name + "_image_image_file").value == '' && $('previous_version_image') == null) {
            alert("Please specify at least a file/image to upload or provide a URL.");
            return false;
        }
    } else {
        if ($('content_blobs__data').value.length == 0 && $('data_url_field').value.length == 0) {
            alert("Please specify at least a file to upload or provide a URL.");
            $('content_blobs__data').focus();
            return false;
        }
    }
    return true;
}

function validateUploadNewVersion(respond_to_content_blobs, resource_name){
    return validateUploadFormFields(respond_to_content_blobs, resource_name);
}

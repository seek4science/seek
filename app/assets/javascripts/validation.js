// Client-side form validation.
//
// These methods are bound to the form submit buttons and return false if the form is invalid,
//   halting event propagation and preventing the form from being submitted.

function validateResourceFields(resourceName, parentId=null) {
    var isNewResource = !!document.getElementById('upload-panel');

    // Check new resource has at least a file/URL
    if (isNewResource && !validateUploadFormFields(resourceName, parentId)) {
        return false;
    }

    // Check the title is present, if the form has a title field
    var title = $j('#' + resourceName + '_title');
    if (title.length && !title.val()) {
        alert("Please specify the title!");
        title.focus();
        title.highlight();
        return false;
    }

    return true;
}

function validateUploadFormFields(resourceName=null, parentId=null) {
    // A file that is still being uploaded straight to the object store has no key yet, so the form cannot
    // be submitted until it has arrived. Say so, rather than complaining that no file was given.
    var inProgressSelector = 'li.direct-upload-in-progress';
    var inProgress = parentId ? $j(`#${parentId} ${inProgressSelector}`) : $j(inProgressSelector);
    if (inProgress.length) {
        alert("Please wait for the file upload to finish.");
        inProgress.first()[0].scrollIntoView();
        inProgress.highlight();
        return false;
    }

    // A file is present if it is in a file input, a remote URL, or has already been uploaded straight to
    // the object store (in which case the form holds the key it was stored under).
    var fileSelectors = 'input[type="file"][name="content_blobs[][data]"], ' +
        'input[type="hidden"][name="content_blobs[][data_url]"], ' +
        'input[type="hidden"][name="content_blobs[][direct_upload_key]"]';
    var files = parentId ? $j(`#${parentId} ${fileSelectors}`) : $j(fileSelectors);

    var hasFiles = files.toArray().some(function (f) { return f.value }); // Count non-blank file fields

    // Also count retained blobs from a previous upload attempt (shown after a validation error)
    if (!hasFiles) {
        const retainedSelector = 'input[name="retained_content_blob_ids[]"]';
        const retained = parentId ? $j(`#${parentId} ${retainedSelector}`) : $j(retainedSelector);
        hasFiles = retained.toArray().some(function (f) { return f.value; });
    }
    var valid = true;

    if ($j('#model_image_image_file').length) { // If it's a model...
        var hasImage = !!$j('#model_image_image_file').val();
        if (!hasFiles && !hasImage) {
            valid = false;
            alert("Please specify at least a file/image to upload or provide a URL.");
        }
    } else {
        if (!hasFiles && !$j('input[name="content_blobs[][data_url]"]').val()) {
            alert("Please specify a file to upload or provide a URL.");
            valid = false;
        }
    }

    if (!valid) {
        let uploadPanel = $j('#upload-panel');
        if (uploadPanel.length) {
            uploadPanel[0].scrollIntoView();
            uploadPanel.highlight();
        }
    }

    return valid;
}



function validateUploadNewVersion() {
    return validateUploadFormFields();
}

function createOrUpdateResource(resourceName) {
    // Disabling the button is handled automatically
    $j('form:has(#' + resourceName + '_submit_btn)').submit();
}

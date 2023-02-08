// Client-side form validation.
//
// These methods are bound to the form submit buttons and return false if the form is invalid,
//   halting event propagation and preventing the form from being submitted.

function validateResourceFields(resourceName) {
    var isNewResource = !!document.getElementById('upload-panel');

    // Check new resource has at least a file/URL
    if (isNewResource && !validateUploadFormFields()) {
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

function validateUploadFormFields() {
    var files= $j('input[type="file"][name="content_blobs[][data]"], input[type="hidden"][name="content_blobs[][data_url]"]');

    var hasFiles = files.toArray().some(function (f) { return f.value }); // Count non-blank file fields
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
    $j('#' + resourceName + '_submit_btn').form().submit();
}

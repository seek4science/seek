// Client-side form validation.
//
// These methods are bound to the form submit buttons and return false if the form is invalid,
//   halting event propagation and preventing the form from being submitted.

function validateResourceFields(resourceName) {
    var isNewResource = !!document.getElementById('upload-panel');

    // Check new resource has at least a file/URL
    if (isNewResource && !validateUploadFormFields(resourceName)) {
        return false;
    }

    // Check the title is present, if the form has a title field
    var title = $j('#' + resourceName + '_title');
    if (title.length && !title.val()) {
        alert("Please specify the title!");
        title.focus();
        return false;
    }

    return true;
}

function validateUploadFormFields(resourceName=null) {
    var files= $j('input[type="file"][name="content_blobs[][data]"], input[type="hidden"][name="content_blobs[][data_url]"]');

    var hasFiles = files.toArray().some(function (f) { return f.value }); // Count non-blank file fields
    var valid = true;
    if (resourceName)
      files.toArray().forEach(file => {
        if (!validateFileExtension(resourceName,file.value)){
          valid = false;
          alert(`Please select a file of format ${resourceName.split("_")[resourceName.split("_").length-1]}`);
        }
      });

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
        var uploadForm = $j('#upload_type_selection').parents('.panel');
        uploadForm[0].scrollIntoView();
        uploadForm.highlight();
    }

    return valid;
}

/**
 * Given a resourceName in the format "data_file_xlsx" with the extension to check as the last item
 * If the requested extension is known, checks if the file conforms to it
 * right now it only considers xlsx files, so it returns true for any other situation
 */
function validateFileExtension(resourceName, filepath){
  extension = resourceName.split("_")[resourceName.split("_").length-1]
  switch (extension) {
    case "xlsx":
      return filepath.split(".")[filepath.split(".").length-1]=="xlsx" ? true : false;
    default:
      return true
  }
}

function validateUploadNewVersion() {
    return validateUploadFormFields();
}

function createOrUpdateResource(resourceName) {
    // Disabling the button is handled automatically
    $j('#' + resourceName + '_submit_btn').form().submit();
}

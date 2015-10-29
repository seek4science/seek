function addExistingFile(text, id) {
    $j('#pending-files').append(HandlebarsTemplates['upload/existing_file']({ id: id, text: text }));
}

function addRemoteFile() {
    var url_element = $j("#data_url_field")[0];
    var original_filename_element = $j("#original_filename")[0];
    var make_local_copy_element = $j("#make_local_copy")[0];

    var remoteFile = {
        dataURL: url_element.value,
        makeALocalCopy: make_local_copy_element.checked ? "1" : "0",
        originalFilename:  original_filename_element.value
    };
    remoteFile.text = remoteFile.originalFilename.blank() ? remoteFile.dataURL : remoteFile.originalFilename;

    var parsed = parseUri(remoteFile.dataURL);
    if (!parsed.host || parsed.host == "null") {
        alert("An invalid URL was provided");
    }
    else {
        $j("#test_url_result")[0].innerHTML = "";
        url_element.value = "";
        original_filename_element.value = "";
        $j('#pending-files').append(HandlebarsTemplates['upload/remote_file'](remoteFile));
    }
}

function addLocalFile() {
    var newField = HandlebarsTemplates['upload/file_field']();
    $j(this).parent().append(newField);

    var filename = this.value.split(/\\/)[this.value.split(/\\/).length - 1];
    var listItem = $j(HandlebarsTemplates['upload/local_file']({ text: filename }));
    $j('#pending-files').append(listItem);
    listItem.append(this.hide());
}

function removeFile() {
    $j(this).parent('li').remove();
    return false;
}

$j(document).ready(function () {
    // Have to bind this event to the pending_files div because the .remove-file links are added dynamically
    //  after page load
    $j('#pending-files').on('click', '.remove-file', removeFile);

    $j('#local-file').on('change', 'input[type=file][data-batch-upload=true]', addLocalFile);
});

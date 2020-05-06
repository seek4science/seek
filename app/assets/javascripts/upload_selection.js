var upload_url_field;
var examine_url_href;

function setup_url_field(examine_url_path,examine_button_id) {
    upload_url_field = $j('#data_url_field');
    examine_url_href = examine_url_path;
    $j('#'+examine_button_id).on('click', function(event){
        submit_url_for_examination();
        return false;
    });
    upload_url_field.on('change', function(event) {
        setTimeout(function(e){
            submit_url_for_examination();
        },0);
        return true;
    });
    upload_url_field.on('keypress',function(event) {
        update_url_checked_status(false);
    });
}

function submit_url_for_examination() {
    var el = $j('#test_url_result');
    el.html('').spinner('add');
    $j.ajax({
        url: examine_url_href,
        method: 'POST',
        data: { data_url: upload_url_field.val() },
        dataType: 'html'
    }).done(function (data) {
        update_url_checked_status(true);
        el.html(data);
    }).fail(function (jqXHR) {
        update_url_checked_status(false);
        el.html(jqXHR.responseText);
    }).always(function () {
        el.spinner('remove');
    });
}

function update_url_checked_status(url_ok) {
    $j("#url_checked")[0].value=url_ok;
    changeUploadButtonText(false);
}

function changeUploadButtonText(isFile) {
    if ($j('[data-upload-button]').length) {
        if (isFile) {
            //data-upload-file-text provides alternative text for when a file is selected
            var text = $j('[data-upload-button]').data('upload-file-text') || 'Upload and Save';
            $j('[data-upload-button]').val(text);
        } else {
            $j('[data-upload-button]').val('Register');
        }
    }
}

$j(document).ready(function () {
    if ($j('#local-file').length) {
        $j('#local-file').on('change', 'input[type=file]', function () { changeUploadButtonText(true); });

        // If the URL field was pre-filled through params, make sure the button text is updated.
        if ($j('#data_url_field').val().length) {
            changeUploadButtonText(false);
        }
    }
});

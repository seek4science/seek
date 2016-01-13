var upload_url_field;
var examine_url_href;

function setup_url_field(examine_url_path,examine_button_id) {
    upload_url_field = $j('#data_url_field');
    examine_url_href = examine_url_path;
    $j('#'+examine_button_id).on('click', function(event){
        submit_url_for_examination();
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
};

function submit_url_for_examination() {
    disallow_copy_option();
    $j('#test_url_result')[0].innerHTML="<p class='large_spinner'/>";
    var data_url = upload_url_field.val();
    $j.post(examine_url_href, { data_url: data_url }, function(data){} );
}

function from_url_selected(){
    Effect.Fade("upload_from_file", {
        duration: 0.0
    });
    Effect.Appear("upload_from_url");
    $j('#upload_from_file_button').removeClass("block_link_active");
    $j('#upload_from_url_button').addClass("block_link_active");
}

function from_file_selected(){
    Effect.Fade("upload_from_url", {
        duration: 0.0
    });
    Effect.Appear("upload_from_file");
    $j('#upload_from_file_button').addClass("block_link_active");
    $j('#upload_from_url_button').removeClass("block_link_active");
}

function allow_copy_option() {
    $j("#copy_option").show();
}

function disallow_copy_option() {
    $j("#copy_option").hide();
    $j("#copy_option input").prop("checked",false);
}

function set_original_filename_for_upload(filename) {
    $j("#original_filename")[0].value=filename;
}

function update_url_checked_status(url_ok) {
    $j("#url_checked")[0].value=url_ok;
}
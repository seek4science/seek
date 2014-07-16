var upload_url_field;
var examine_url_href;
function setup_url_field(upload_field, examine_url_path,examine_button_id) {
    upload_url_field = $j('#'+upload_field+'_data_url');
    examine_url_href = examine_url_path;
    $j('#'+examine_button_id).on('click', function(event){
        submit_url_for_examination();
    });
    upload_url_field.on('paste', function(event) {
        setTimeout(function(e){
            submit_url_for_examination();
        },0);
        return true;
    });
};
function submit_url_for_examination() {
    var data_url = upload_url_field.val();
    $j.post(examine_url_href + "?data_url=" + data_url, function(data){} );
}
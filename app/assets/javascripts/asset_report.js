function update_displayed_report(id) {
    var selected = $(id).value;
    $$('select#'+id+' option').each(function(option) {
        var val = option.value;
        if (val == selected) {
            $(val).show();
        }
        else {
            $(val).hide();
        }
    });
}
function displayed_sharing_report_changed() {
    update_displayed_report('displayed_sharing_report');
}
function displayed_unlinked_report_changed() {
    update_displayed_report('displayed_unlinked_report');
}
function displayed_publication_report_changed() {
    update_displayed_report('displayed_publication_report');
}
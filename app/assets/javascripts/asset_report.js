function update_displayed_report(id) {
    var selector = $j('#' + id);
    $j('.asset_report_container', selector.parents('.tab-pane')).hide();
    $j('#' + selector.val()).show();
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

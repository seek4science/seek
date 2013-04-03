function getPublishParams() {
    var checkbox_elements = document.getElementsByClassName('checkbox_element');
    var checked_elements = [];
    var json = {}
    for (var i = 0; i < checkbox_elements.length; i++) {
        if (checkbox_elements[i].checked) {
            var checked_element_id = checkbox_elements[i].id
            var asset_type = checked_element_id.split("_")[1];
            var asset_id = checked_element_id.split("_")[2];
            checked_elements.push([asset_type, asset_id]);
            if (json[asset_type] == null) {
                json[asset_type] = {};
                json[asset_type][asset_id] = 1;
            } else {
                json[asset_type][asset_id] = 1;
            }
        }
    }
    return JSON.stringify(json);
}

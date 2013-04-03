function getPublishingItems(){
    var checkbox_elements = document.getElementsByClassName('checkbox_element');
    var checked_elements = [];
    for (var i = 0; i < checkbox_elements.length; i++) {
        if (checkbox_elements[i].checked) {
            var checked_element_id = checkbox_elements[i].id
            var asset_type = checked_element_id.split("_")[1];
            var asset_id = checked_element_id.split("_")[2];
            checked_elements.push([asset_type, asset_id]);
        }
    }
    return checked_elements;
}

function getJsonPublishParams() {
    var publishing_items = getPublishingItems();
    var json = {}
    for (var i = 0; i < publishing_items.length; i++) {
        var asset_type = publishing_items[i][0];
        var asset_id = publishing_items[i][1];

        if (json[asset_type] == null) {
            json[asset_type] = {};
            json[asset_type][asset_id] = 1;
        } else {
            json[asset_type][asset_id] = 1;
        }
    }
    return JSON.stringify(json);
}

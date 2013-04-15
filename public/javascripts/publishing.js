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

function checkGatekeeperRequired(all_items) {
    var gatekeeper_required = 'false';
    var publishing_items = getPublishingItems();

    for (var i = 0; i < publishing_items.length; i++) {
        var asset_type = publishing_items[i][0];
        var asset_id = publishing_items[i][1];
        for (var j = 0; j < all_items.length; j++) {
            if (asset_type == all_items[j][0] && asset_id == all_items[j][1]) {
                gatekeeper_required = all_items[j][3];
                if (gatekeeper_required == 'true'){
                    break;
                    break;
                }
            }
        }
    }

    if (gatekeeper_required == 'true') {
        clickLink($('waiting_approval_list'));
    }
    else {
        $('publishing_form').submit();
    }
}

function checkRelatedItems(all_items) {
    var publishing_items = getPublishingItems();
    var contain_related_items = 'false';
    for (var i = 0; i < publishing_items.length; i++) {
        var asset_type = publishing_items[i][0];
        var asset_id = publishing_items[i][1];
        for (var j = 0; j < all_items.length; j++) {
            if (asset_type == all_items[j][0] && asset_id == all_items[j][1]) {
                contain_related_items = all_items[j][2];
                if (contain_related_items == 'true'){
                    break;
                    break;
                }
            }
        }
    }

    //confirmation if you wish to publish related items?
    if (contain_related_items == 'true'){
        var confirm_message = "";
        var publishing_form = $('publishing_form');
        var base_URI = publishing_form.baseURI;
        if (base_URI.match('people') != null)
            confirm_message =  confirm_message + "There are items related to the selected asset(s). They are ISA items and their assets. Would you like to process publishing them as well? (A preview will be given)"
        else{
            confirm_message = confirm_message + "There are items related to this asset. They are ISA items and their assets. Would you like to process publishing them as well? (A preview will be given)"
        }
        if (confirm(confirm_message)) {

            if (base_URI.match('people') != null)
                publishing_form.action = 'publish_related_items';
            else{
                publishing_form.action = base_URI + '/publish_related_items';
            }
            publishing_form.method = 'get';
            publishing_form.submit();
        } else
            checkGatekeeperRequired(all_items);
    }else
        checkGatekeeperRequired(all_items);
}

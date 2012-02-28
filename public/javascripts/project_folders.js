var tree;
var elementFolderIds = new Array();
var displayed_folder_id = 0;

function item_dropped_to_folder(element, droppable_element, project_id) {
    var folder_id = elementFolderIds[droppable_element.id];
    if (folder_id != displayed_folder_id) {
        var dropped_id = element.id;
        var split_ids = dropped_id.split("_");
        var origin_folder_id = split_ids[2];
        var origin_folder_element_id = element_id_for_folder_id(origin_folder_id);
        var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/move_asset_to";
        path += "?asset_id=" + split_ids[1] + "&asset_type=" + split_ids[0] + "&dest_folder_id=" + folder_id;
        path += "&dest_folder_element_id=" + droppable_element.id + "&origin_folder_element_id=" + origin_folder_element_id;

        new Ajax.Request(path, {
            asynchronous:true,
            evalScripts:true
        });
    }
    else {
        alert("The item is already in that folder.");
    }
}

function remove_item_from_assay(element,droppable_element,project_id) {
    var dropped_id = element.id;
    var split_ids = dropped_id.split("_");
    var origin_folder_id = split_ids[2]+"_"+split_ids[3];
    var origin_folder_element_id = element_id_for_folder_id(origin_folder_id);
    var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/remove_asset";
    path += "?asset_id=" + split_ids[1] + "&asset_type=" + split_ids[0];
    path += "&origin_folder_element_id=" + origin_folder_element_id;
    new Ajax.Request(path, {
        asynchronous:true,
        evalScripts:true
    });
}

function element_id_for_folder_id(folder_id) {
    var folder_element_id;
    for (var key in elementFolderIds) {
        if (elementFolderIds[key] == folder_id) {
            folder_element_id = key;
        }
    }
    return folder_element_id;
}

function folder_clicked(folder_id, project_id) {
    show_ajax_loader('folder_contents');
    var path = "/projects/" + project_id + "/folders/" + folder_id + "/display_contents";
    displayed_folder_id = folder_id;
    new Ajax.Request(path, {asynchronous:true, evalScripts:true});


}

function create_child() {
    var child_form = $("create_child_form");
    var title = child_form.title.value;
    if (title.strip().length < 2) {
        alert("New folder name is too short.");
    }
    else {
        child_form.commit.disable();
        child_form.commit.value = "Creating ...";
        if (child_form.onsubmit()) {
            child_form.submit();
        }
    }
}

function focus_folder(folder_id) {
    var element_id = element_id_for_folder_id(folder_id);
    if ($(element_id)) {
        $(element_id.gsub("label", "content")).toggleClassName("ygtvfocus");
    }
}
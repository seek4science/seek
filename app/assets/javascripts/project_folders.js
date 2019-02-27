var tree;
var elementFolderIds = [];
var displayed_folder_id = 0;

function setupFoldersTree(dataJson, container_id,drop_accept_class) {
    $j('#'+container_id).bind('loaded.jstree', function () {
        $j('#'+container_id+' .jstree-anchor').droppable({
            accept: '.'+drop_accept_class,
            hoverClass: 'folder_hover',
            tolerance: 'pointer',
            drop: function(event,ui) {
                var folder_element_id=$j(this).attr('id');
                var folder_id=$j('#'+container_id).jstree(true).get_node(folder_element_id).data.folder_id;
                item_dropped_to_folder(ui.draggable,folder_id);
            }
        });
    }).jstree({
        'core': {
            'data': dataJson
        }
    }).on('activate_node.jstree', function (e, data) {
        var folder_id = $j(this).jstree(true).get_node(data.node.id).data.folder_id;
        var project_id = $j(this).jstree(true).get_node(data.node.id).data.project_id;
        folder_clicked(folder_id, project_id);
    });
}

function remove_item_from_assay(item_element) {
    var project_id=item_element.data('project-id');
    var origin_folder_id=item_element.data('origin-folder-id');
    var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/remove_asset";

    $j.ajax({ url: path,
        type: 'POST',
        dataType: 'script',
        data: {
            asset_id: item_element.data('asset-id'),
            asset_type: item_element.data('asset-class'),
            asset_element_id: item_element.attr('id')
        }
    });
}

function setupAssayRemoveDropTarget(target_id) {
    $j('#'+target_id).droppable({
        accept: '.draggable_assay_folder_item',
        hoverClass: 'folder_hover',
        tolerance: 'pointer',
        drop: function (event, ui) {
            remove_item_from_assay(ui.draggable);
        }
    });
}

function updateFolderLabel(folder_id,new_label) {
    //this is a workaround to using rename_node, which loses the droppable.
    var tree_id=$j('li#folder_'+folder_id).parents('.jstree').attr('id');
    var selector='#'+tree_id+' li#folder_'+folder_id+' a';
    var contents = $j(selector).contents();
    contents[contents.length - 1].nodeValue = new_label;
}

function setupAssetCardDraggable(card_class) {
    $j('.'+card_class).draggable({
        revert: 'invalid',
        opacity: 0.3,
        start: function(event,ui) {
            if ($j("remove_from_assay_drop_area")) {
                $j("#remove_from_assay_drop_area").fadeIn(200);
            }
        },
        stop: function(event,ui) {
            if ($j("remove_from_assay_drop_area")) {
                $j("#remove_from_assay_drop_area").fadeOut(200);
            }
        }
    });
}

function item_dropped_to_folder(item_element,dest_folder_id) {
    if (dest_folder_id != displayed_folder_id) {
        var folder_element_id='folder_'+dest_folder_id;
        var project_id=item_element.data('project-id');
        var origin_folder_id=item_element.data('origin-folder-id');
        var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/move_asset_to";

        $j.ajax({ url: path,
            type: 'POST',
            dataType: 'script',
            data: {
                asset_id: item_element.data('asset-id'),
                asset_type: item_element.data('asset-class'),
                dest_folder_id: dest_folder_id,
                dest_folder_element_id: folder_element_id,
                asset_element_id: item_element.attr('id')
            }
        });
    }
    else {
        alert("The item is already in that folder.");
    }
}

function folder_clicked(folder_id, project_id) {
    $j('#folder_contents').spinner('add');
    var path = "/projects/" + project_id + "/folders/" + folder_id + "/display_contents";
    displayed_folder_id = folder_id;
    $j.ajax({ url: path, dataType: 'script' });
}

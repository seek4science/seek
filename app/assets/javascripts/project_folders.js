var tree;
var elementFolderIds = new Array();
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

    var asset_element_id=item_element.attr('id');
    var project_id=item_element.data('project-id');
    var asset_id=item_element.data('asset-id');
    var asset_class=item_element.data('asset-class');
    var origin_folder_id=item_element.data('origin-folder-id');

    var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/remove_asset";
    path += "?asset_id=" + asset_id + "&asset_type=" + asset_class+"&asset_element_id="+asset_element_id;;

    new Ajax.Request(path, {
        asynchronous:true,
        evalScripts:true
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
    $j('.'+card_class).draggable(
        {
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
        }
    );
}




function item_dropped_to_folder(item_element,dest_folder_id) {
    if (dest_folder_id != displayed_folder_id) {

        var folder_element_id='folder_'+dest_folder_id;

        var asset_element_id=item_element.attr('id');
        var project_id=item_element.data('project-id');
        var asset_id=item_element.data('asset-id');
        var asset_class=item_element.data('asset-class');
        var origin_folder_id=item_element.data('origin-folder-id');

        var path = "/projects/" + project_id + "/folders/" + origin_folder_id + "/move_asset_to";
        path += "?asset_id=" + asset_id + "&asset_type=" + asset_class + "&dest_folder_id=" + dest_folder_id;
        path += "&dest_folder_element_id=" + folder_element_id + "&asset_element_id="+asset_element_id;

        new Ajax.Request(path, {
            asynchronous:true,
            evalScripts:true
        });
    }
    else {
        alert("The item is already in that folder.");
    }
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
    show_large_ajax_loader('folder_contents');
    var path = "/projects/" + project_id + "/folders/" + folder_id + "/display_contents";
    displayed_folder_id = folder_id;
    new Ajax.Request(path, {asynchronous:true, evalScripts:true});


}


function focus_folder(folder_id) {
    var element_id = element_id_for_folder_id(folder_id);
    if ($(element_id)) {
        $(element_id.gsub("label", "content")).toggleClassName("ygtvfocus");
    }
}

Draggables.addObserver({
  onStart:function( eventName, draggable, event )
  {
    if ($("remove_from_assay_drop_area")) {
        Effect.Appear("remove_from_assay_drop_area",{duration:0.5});
    }
  },
  onEnd:function( eventName, draggable, event )
  {
    if ($("remove_from_assay_drop_area")) {
        Effect.Fade("remove_from_assay_drop_area",{duration:0.5});
    }
  }
});
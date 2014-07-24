var item_index = 0;

setupFileElement($j("#content_blob_data"));

function setupFileElement(element) {
    element.on('change', function (event) {
        this.name = "content_blob[data_" + item_index + "]";
        this.id = 'data_' + item_index;
        this.hide();
        var new_element = $j('<input>', {
            type: 'file',
            name: 'content_blob[data]'
        })[0];
        var filename = this.value.split(/\\/)[this.value.split(/\\/).length - 1];
        showInList(filename, item_index);
        this.parentNode.insertBefore(new_element, this);
        item_index++;
        setupFileElement(new_element);

    });
}

function addBatchFormElement(prefix, value, index) {
    var root_element = $j("#batch_items_list")[0];
    var new_element = document.createElement('input');
    new_element.type = 'hidden';
    new_element.name = 'content_blob[' + prefix + '_' + index + ']';
    new_element.value = value;
    new_element.id = prefix + "_" + index;

    root_element.appendChild(new_element);
}

function removeBatchFormItem(index) {
    $j("#pending_item_" + index)[0].remove();
    if ($j("#data_url_" + index)[0]) {
        $j("#data_url_" + index)[0].remove();
        $j("#original_filename_" + index)[0].remove();
        $j("#make_local_copy_" + index)[0].remove();
    }
    if ($j("#data_" + index)[0]) {
        $j("#data_" + index)[0].remove();
    }
}

function showInList(text, index) {
    //FIXME: improve this by constucting using jquery
    var pending_id = "'pending_item_" + index + "'";
    var new_element = $j("<li id=" + pending_id + "><span id='generic_file_icon'></span>&nbsp;" + text + "</li>").appendTo($j('#pending_files'));
    new_element.append($j("<a href='#' onclick='removeBatchFormItem(" + index + ");return false;'>Remove</a>"));

}

function addToList() {
    var url_element = $j("#data_url_field")[0];
    var original_filename_element = $j("#original_filename")[0];
    var url = url_element.value;
    var original_filename = original_filename_element.value;
    var make_local_copy_element = $j("#make_local_copy")[0];
    var make_local_copy = make_local_copy_element.checked ? "1" : "0";


    var parsed = parseUri(url);

    if (!parsed.protocol || !parsed.host || parsed.host == "null") {
        alert("An invalid URL was provided");
    }
    else {
        //create elements for form
        addBatchFormElement("data_url", url, item_index);
        addBatchFormElement("original_filename", original_filename, item_index);
        addBatchFormElement("make_local_copy", make_local_copy, item_index);
        url_element.value = "";
        original_filename_element.value = "";
        $j("#test_url_result")[0].innerHTML = "";
        var display_name = original_filename.blank() ? url : original_filename;
        showInList(display_name, item_index);
        item_index++;

    }
}
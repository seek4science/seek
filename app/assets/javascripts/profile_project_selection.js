function others(element_id) {
    //check if the selected item is 'Other'
    var selected_texts = selectedEntryTexts(element_id);
    var check_flag = false;
    for (var i = 0; i < selected_texts.length; i++) {
        if (selected_texts[i] == 'Others') {
            check_flag = true;
            break;
        }
    }
    if (check_flag == true) {
        Effect.Appear('other_' + element_id, { duration: 0.5 });
    } else {
        Effect.Fade('other_' + element_id, { duration: 0.25 });
    }
}

function selectedEntryTexts(element_id) {
    var selectedArray = new Array();
    var selObj = document.getElementById(element_id);
    var i;
    var count = 0;
    for (i = 0; i < selObj.options.length; i++) {
        if (selObj.options[i].selected) {
            selectedArray[count] = selObj.options[i].text;
            count++;
        }
    }
    return selectedArray;
}

function checkRepeatedItems(checkbox_element) {
    var repeated_class = checkbox_element.className;
    var repeated_elements = document.getElementsByClassName(repeated_class);
    var check = checkbox_element.checked;

    for(var i=0;i<repeated_elements.length;i++){
        repeated_elements[i].checked = check;
    }
}

function selectChildren(select_all_element){
    var scrollPosition = $j(window).scrollTop();
    console.log(scrollPosition)

    var children_checkboxes = $j(':checkbox', $j(select_all_element).parent().parent().parent())
    for(var i=0;i<children_checkboxes.length;i++){
        var checkbox_element = { className: children_checkboxes[i].className, checked: true }
        checkRepeatedItems(checkbox_element)
    }

    console.log($j(window).scrollTop())
    $j(window).scrollTop(scrollPosition);
    console.log('No scrolling please.')
}

function deselectChildren(deselect_all_element){
    var children_checkboxes = $j(':checkbox', $j(deselect_all_element).parent().parent().parent())
    for(var i=0;i<children_checkboxes.length;i++){
        var checkbox_element = { className: children_checkboxes[i].className, checked: false }
        checkRepeatedItems(checkbox_element)
    }

}

function checkRepeatedItems(checkbox_element) {
    var repeated_class = checkbox_element.className;
    var repeated_elements = document.getElementsByClassName(repeated_class);
    var check = checkbox_element.checked;

    for(var i=0;i<repeated_elements.length;i++){
        repeated_elements[i].checked = check;
    }
}
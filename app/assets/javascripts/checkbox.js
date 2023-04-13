function selectChildren(select_all_element,parent_selector){
    let children_checkboxes = $j(':checkbox', $j(select_all_element).parents(parent_selector))
    for(let checkbox of children_checkboxes){
        let checkbox_element = { className: checkbox.className, checked: true }
        checkRepeatedItems(checkbox_element)
    }
}

function deselectChildren(deselect_all_element,parent_selector){
    let children_checkboxes = $j(':checkbox', $j(deselect_all_element).parents(parent_selector))
    for(let checkbox of children_checkboxes){
        let checkbox_element = { className: checkbox.className, checked: false }
        checkRepeatedItems(checkbox_element)
    }
}

function checkRepeatedItems(checkbox_element) {
    let repeated_elements = document.getElementsByClassName(checkbox_element.className)
    let check = checkbox_element.checked
    for(let element of repeated_elements){
        element.checked = check
    }
}
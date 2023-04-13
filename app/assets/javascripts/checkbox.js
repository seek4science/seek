$j(document).ready(function () {
    $j("a.selectChildren").click(function (event) {
        event.preventDefault();
        selectChildren(this,$j(this).data("cb_parent_selector"))
    })
    $j("a.deselectChildren").click(function (event) {
        event.preventDefault();
        deselectChildren(this,$j(this).data("cb_parent_selector"))
    })
    $j('#jstree').on('click', 'a.selectChildren', function (event) {
        event.preventDefault();
        selectChildren(this,$j(this).data("cb_parent_selector"))
    })
    $j('#jstree').on('click', 'a.deselectChildren', function (event) {
        event.preventDefault();
        deselectChildren(this,$j(this).data("cb_parent_selector"))
    })
})

function selectChildren(select_all_element,cb_parent_selector){
    let children_checkboxes = $j(':checkbox', $j(select_all_element).parents(cb_parent_selector))
    for(let checkbox of children_checkboxes){
        let checkbox_element = { className: checkbox.className, checked: true }
        checkRepeatedItems(checkbox_element)
    }
}

function deselectChildren(deselect_all_element,cb_parent_selector){
    let children_checkboxes = $j(':checkbox', $j(deselect_all_element).parents(cb_parent_selector))
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
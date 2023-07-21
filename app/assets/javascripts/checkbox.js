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
    $j("a.managed_by_toggle").click(function () {
        toggleManagers(this,$j(this).data("managed_by_selector"))
    })
    $j("div.isa-tree-toggle-open").click(function () {
        isaTreeShow(this,$j(this).data("cb_parent_selector"))
    })
    $j("div.isa-tree-toggle-close").click(function () {
        isaTreeHide(this,$j(this).data("cb_parent_selector"))
    })
    $j("a.collapseChildren").click(function (event) {
        event.preventDefault();
        collapseRecursively($j(this).data("cb_parent_selector"))
    })
    $j("a.expandChildren").click(function (event) {
        event.preventDefault();
        expandRecursively($j(this).data("cb_parent_selector"))
    })
    $j(".hideBlocked").click(function (event) {
        event.preventDefault();
        hideBlocked($j(this).data("cb_parent_selector"),$j(this).data("blocked_selector"))
    })
    $j(".showBlocked").click(function (event) {
        event.preventDefault();
        showBlocked($j(this).data("cb_parent_selector"),$j(this).data("blocked_selector"))
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

function toggleManagers(item,managed_by_selector) {
    $j(managed_by_selector).toggle()
}

function isaTreeShow(item,cb_parent_selector) {
    let children_assets = $j('.isa-tree', $j(item).parents(cb_parent_selector))
    if(cb_parent_selector.includes('split_button_parent')){
        children_assets.splice(0, 1);
    }
    let keep_closed = []
    for (let asset of children_assets) {
        $j(asset).show()
        for (let caret of $j('.isa-tree-toggle-close', $j(asset))){
            if (caret.style.display == "none"){
                keep_closed.push(caret)
            }
        }
    }
    $j($j('.isa-tree-toggle-open', $j(item).parents(cb_parent_selector))[0]).hide()
    $j($j('.isa-tree-toggle-close', $j(item).parents(cb_parent_selector))[0]).show()

    for (let caret of keep_closed){
        isaTreeHide(caret,$j(caret).data("cb_parent_selector"))
    }
}
function isaTreeHide(item,cb_parent_selector){
    let children_assets = $j('.isa-tree', $j(item).parents(cb_parent_selector))
    if(cb_parent_selector.includes('split_button_parent')){
        children_assets.splice(0, 1);
    }
    for (let asset of children_assets) {
        $j(asset).hide()
    }
    $j($j('.isa-tree-toggle-open', $j(item).parents(cb_parent_selector))[0]).show()
    $j($j('.isa-tree-toggle-close', $j(item).parents(cb_parent_selector))[0]).hide()
}

function collapseRecursively(cb_parent_selector){
    let children_assets = $j('[class^=isa-tree-toggle]', $j(cb_parent_selector))
    for (let asset of children_assets) {
        isaTreeHide(asset,$j(asset).data("cb_parent_selector"))
    }
}

function expandRecursively(cb_parent_selector){
    let children_assets = $j('[class^=isa-tree-toggle]', $j(cb_parent_selector))
    for (let asset of children_assets) {
        isaTreeShow(asset,$j(asset).data("cb_parent_selector"))
    }
}

function hideBlocked(cb_parent_selector,blocked_selector){
    let children_assets = $j(blocked_selector, $j(cb_parent_selector))
    for (let asset of children_assets) {
        // Don't hide "parents" of non-blocked items
        if(!$j('input[type=checkbox]',$j(asset).parent()).length>0) {
            $j($j(asset).parents('div.split_button_parent')[0]).hide()
        }
    }
}

function showBlocked(cb_parent_selector,blocked_selector){
    let children_assets = $j(blocked_selector, $j(cb_parent_selector))
    for (let asset of children_assets) {
        $j($j(asset).parents('div.split_button_parent')[0]).show()
    }
}

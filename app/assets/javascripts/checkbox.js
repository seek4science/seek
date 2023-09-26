$j(document).ready(function () {
    $j("a.selectChildren").click(selectChildren);
    $j("a.deselectChildren").click(deselectChildren);
    $j("a.managed_by_toggle").click(toggleManagers);
    $j("a.permissions_toggle").click(function () {
        togglePermissions($j(this).closest('.isa-tree'));

        return false;
    });
    $j("a.showPermissions").click(function () {
        togglePermissions($j(this).closest('.batch-selection-scope'), 'show');

        return false;
    })
    $j("a.hidePermissions").click(function () {
        togglePermissions($j(this).closest('.batch-selection-scope'), 'hide');

        return false;
    })
    $j(".isa-tree-toggle-open").click(isaTreeShow);
    $j(".isa-tree-toggle-close").click(isaTreeHide);
    $j("a.collapseChildren").click(collapseRecursively);
    $j("a.expandChildren").click(expandRecursively);
    $j(".hideBlocked").click(hideBlocked);
    $j(".showBlocked").click(showBlocked);
})

function selectChildren() {
    let children_checkboxes = $j(':checkbox', $j(this).closest('.batch-selection-scope'));
    for(let checkbox of children_checkboxes){
        let checkbox_element = { className: checkbox.className, checked: true }
        checkRepeatedItems(checkbox_element)
    }

    return false;
}

function deselectChildren() {
    let children_checkboxes = $j(':checkbox', $j(this).closest('.batch-selection-scope'));
    for(let checkbox of children_checkboxes){
        let checkbox_element = { className: checkbox.className, checked: false }
        checkRepeatedItems(checkbox_element)
    }

    return false;
}

function checkRepeatedItems(checkbox_element) {
    let repeated_elements = document.getElementsByClassName(checkbox_element.className)
    let check = checkbox_element.checked
    for(let element of repeated_elements){
        element.checked = check
    }
}

function button_checkRepeatedItems(button_element) {
    if(this.event.target.nodeName.includes("BUTTON")){
        let checkbox_element = $j(button_element).find('input')[0]
        checkbox_element.checked = !(checkbox_element.checked)
        checkRepeatedItems(checkbox_element)
    }
}

function toggleManagers() {
    $j(this).siblings('.managed_by_list').toggle();

    return false;
}

function togglePermissions(scope, state) {
    const permissions = $j('.permission_list', scope);
    switch(state){
        case 'show':
            permissions.show()
            break
        case 'hide':
            permissions.hide()
            break
        default:
            permissions.toggle()
    }
}

function isaTreeShow() {
    $j(this).closest('.batch-selection-scope').children('.collapse-scope').show();
    $j(this).siblings('.isa-tree-toggle-close').show();
    $j(this).hide();

    return false;
}

function isaTreeHide(){
    $j(this).closest('.batch-selection-scope').children('.collapse-scope').hide();
    $j(this).siblings('.isa-tree-toggle-open').show();
    $j(this).hide();

    return false;
}

function collapseRecursively() {
    const scope = $j(this).closest('.batch-selection-scope').children('.collapse-scope');
    const toggles = $j('.isa-tree-toggle-close', scope);
    for (let toggle of toggles) {
        if (toggle.style.display === 'none') // Skip those that are already closed
            continue;
        isaTreeHide.apply(toggle);
    }

    return false;
}

function expandRecursively() {
    const scope = $j(this).closest('.batch-selection-scope').children('.collapse-scope');
    const toggles = $j('.isa-tree-toggle-open', scope);
    for (let toggle of toggles) {
        if (toggle.style.display === 'none')
            continue;
        isaTreeShow.apply(toggle);
    }

    return false;
}

function hideBlocked(){
    let children_assets = $j($j(this).data('blocked_selector'), $j(this).closest('.batch-selection-scope'));
    for (let asset of children_assets) {
        //Items in isa tree
        if($j($j(asset).parents('div.split_button_parent')).length>0) {
            // Don't hide "parents" of non-blocked items
            if (!$j('input[type=checkbox]', $j(asset).parent()).length > 0) {
                $j($j(asset).parents('div.split_button_parent')[0]).hide()
            }
        //Items not in isa tree
        } else {
            $j(asset).hide()
        }
    }

    return false;
}

function showBlocked(){
    let children_assets = $j($j(this).data('blocked_selector'), $j(this).closest('.batch-selection-scope'));
    for (let asset of children_assets) {
        if($j($j(asset).parents('div.split_button_parent')).length>0) {
            $j($j(asset).parents('div.split_button_parent')[0]).show()
        } else{
            $j(asset).show()
        }
    }

    return false;
}

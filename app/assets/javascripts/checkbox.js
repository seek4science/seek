$j(document).ready(function () {
    $j("a.selectChildren").click(BatchAssetSelection.selectChildren);
    $j("a.deselectChildren").click(BatchAssetSelection.deselectChildren);
    $j("a.managed_by_toggle").click(BatchAssetSelection.toggleManagers);
    $j("a.permissions_toggle").click(function () {
        BatchAssetSelection.togglePermissions($j(this).closest('.isa-tree'));
        return false;
    });
    $j("a.showPermissions").click(function () {
        BatchAssetSelection.togglePermissions($j(this).closest('.batch-selection-scope'), 'show');
        return false;
    })
    $j("a.hidePermissions").click(function () {
        BatchAssetSelection.togglePermissions($j(this).closest('.batch-selection-scope'), 'hide');
        return false;
    })
    $j(".batch-asset-collapse-toggle").click(function () {
        BatchAssetSelection.toggleCollapse(this);
        return false;
    });
    $j("a.collapseChildren").click(BatchAssetSelection.collapseRecursively);
    $j("a.expandChildren").click(BatchAssetSelection.expandRecursively);
    $j(".hideBlocked").click(BatchAssetSelection.hideBlocked);
    $j(".showBlocked").click(BatchAssetSelection.showBlocked);
    $j(".batch-asset-select-btn").click(function (event) {
        if (event.target.nodeName.includes("BUTTON")) {
            $j(this).find(':checkbox').click();
        }
    });
    $j('.batch-asset-select-btn :checkbox').click(function () {
        BatchAssetSelection.checkRepeatedItems(this.className, this.checked);
    });
});

const BatchAssetSelection = {
    selectChildren: function (event) {
        event.preventDefault();
        BatchAssetSelection.setChildren($j(this).closest('.batch-selection-scope'), true);
    },

    deselectChildren: function (event) {
        event.preventDefault();
        BatchAssetSelection.setChildren($j(this).closest('.batch-selection-scope'), false);
    },

    setChildren: function (scope, value) {
        const children = $j(':checkbox', scope);
        const classes = new Set();
        for (let child of children) {
            classes.add(child.className);
        }

        classes.forEach(c => BatchAssetSelection.checkRepeatedItems(c, value));
    },

    checkRepeatedItems: function (className, check) {
        document.getElementById('batch-asset-selection')
            .querySelectorAll('.' + className).forEach(e => e.checked = check);
    },

    toggleManagers: function () {
        $j('.managed_by_list', $j(this).closest('.isa-tree')).toggle();

        return false;
    },

    togglePermissions: function (scope, state) {
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
    },

    toggleCollapse: function (element, state) {
        if (state === undefined) {
            state = !element.classList.contains('open');
        }
        element.classList.toggle('open', state);
        $j(element).closest('.batch-selection-scope').children('.batch-asset-collapse-scope').toggle(state);
    },

    collapseRecursively: function () {
        const scope = $j(this).closest('.batch-selection-scope').children('.batch-asset-collapse-scope');
        const toggles = $j('.batch-asset-collapse-toggle', scope);
        for (let toggle of toggles) {
            BatchAssetSelection.toggleCollapse(toggle, false);
        }

        return false;
    },

    expandRecursively: function () {
        const scope = $j(this).closest('.batch-selection-scope').children('.batch-asset-collapse-scope');
        const toggles = $j('.batch-asset-collapse-toggle', scope);
        for (let toggle of toggles) {
            BatchAssetSelection.toggleCollapse(toggle, true);
        }

        return false;
    },

    hideBlocked: function () {
        let children_assets = $j($j(this).data('blocked_selector'), $j(this).closest('.batch-selection-scope'));
        for (let asset of children_assets) {
            //Items in isa tree
            if ($j($j(asset).parents('div.batch-asset-selection-isa')).length > 0) {
                // Don't hide "parents" of non-blocked items
                if (!$j('input[type=checkbox]', $j(asset).parent()).length > 0) {
                    $j($j(asset).parents('div.batch-asset-selection-isa')[0]).hide();
                }
                //Items not in isa tree
            } else {
                $j(asset).hide();
            }
        }

        return false;
    },

    showBlocked: function () {
        let children_assets = $j($j(this).data('blocked_selector'), $j(this).closest('.batch-selection-scope'));
        for (let asset of children_assets) {
            if ($j($j(asset).parents('div.batch-asset-selection-isa')).length > 0) {
                $j($j(asset).parents('div.batch-asset-selection-isa')[0]).show()
            } else {
                $j(asset).show()
            }
        }

        return false;
    }
}

$j(document).ready(function () {
    $j("a.selectChildren").click(BatchAssetSelection.selectChildren);
    $j("a.deselectChildren").click(BatchAssetSelection.deselectChildren);
    $j("a.managed_by_toggle").click(BatchAssetSelection.toggleManagers);
    $j("a.permissions_toggle").click(function (event) {
        event.preventDefault();
        $j('.permission_list:first', $j(this).closest('.batch-selection-scope')).toggle();
    });
    $j("a.showPermissions").click(function (event) {
        event.preventDefault();
        $j('.permission_list', $j(this).closest('.batch-selection-scope')).show();
    })
    $j("a.hidePermissions").click(function (event) {
        event.preventDefault();
        $j('.permission_list', $j(this).closest('.batch-selection-scope')).hide();
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
        const scope = $j(this).closest('.batch-selection-scope');
        const children = $j($j(this).data('blocked_selector'), scope).closest('.batch-asset-selection-isa');
        for (let child of children) {
            const element = $j(child);
            // Don't hide if any non-blocked children
            if (!$j(':checkbox', element).length) {
                element.hide();
            }
        }

        return false;
    },

    showBlocked: function () {
        const scope = $j(this).closest('.batch-selection-scope');
        $j($j(this).data('blocked_selector'), scope).closest('.batch-asset-selection-isa').show();

        return false;
    }
}

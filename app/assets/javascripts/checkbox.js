$j(document).ready(function () {
    $j('.batch-selection-select-children').click(BatchAssetSelection.selectChildren);
    $j('.batch-selection-deselect-children').click(BatchAssetSelection.deselectChildren);
    $j('.batch-selection-collapse-children').click(BatchAssetSelection.collapseRecursively);
    $j('.batch-selection-expand-children').click(BatchAssetSelection.expandRecursively);
    $j('.batch-selection-show-permissions').click(function (event) {
        event.preventDefault();
        $j('.batch-selection-permission-list', $j(this).closest('.batch-selection-scope')).show();
    })
    $j('.batch-selection-hide-permissions').click(function (event) {
        event.preventDefault();
        $j('.batch-selection-permission-list', $j(this).closest('.batch-selection-scope')).hide();
    })
    $j('.batch-selection-hide-blocked').click(BatchAssetSelection.hideBlocked).click(); // Trigger on page load
    $j('.batch-selection-show-blocked').click(BatchAssetSelection.showBlocked);
    $j('.batch-selection-collapse-toggle').click(function () {
        BatchAssetSelection.toggleCollapse(this);
        return false;
    });
    $j('.batch-selection-check-btn').click(function (event) {
        if (event.target.nodeName.includes('BUTTON')) {
            $j(this).find(':checkbox').click();
        }
    });
    $j('.batch-selection-check-btn :checkbox').click(function () {
        BatchAssetSelection.checkRepeatedItems(this.className, this.checked);
    });
    $j('.batch-selection-managed-by-toggle').click(function (event) {
        event.preventDefault();
        $j('.batch-selection-managed-by-list:first', $j(this).closest('.batch-selection-scope')).toggle();
    });
    $j('.batch-selection-permissions-toggle').click(function (event) {
        event.preventDefault();
        $j('.batch-selection-permission-list:first', $j(this).closest('.batch-selection-scope')).toggle();
    });
});

const BatchAssetSelection = {
    blockedSelectors: '.not-visible, .not-manageable, .already-published',
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
        $j('.batch-selection-managed-by-list', $j(this).closest('.batch-selection-asset')).toggle();

        return false;
    },

    toggleCollapse: function (element, state) {
        if (state === undefined) {
            state = !element.classList.contains('open');
        }
        element.classList.toggle('open', state);
        $j(element).closest('.batch-selection-scope').children('.batch-selection-collapse').toggle(state);
    },

    collapseRecursively: function () {
        const scope = $j(this).closest('.batch-selection-scope').children('.batch-selection-collapse');
        const toggles = $j('.batch-selection-collapse-toggle', scope);
        for (let toggle of toggles) {
            BatchAssetSelection.toggleCollapse(toggle, false);
        }

        return false;
    },

    expandRecursively: function () {
        const scope = $j(this).closest('.batch-selection-scope').children('.batch-selection-collapse');
        const toggles = $j('.batch-selection-collapse-toggle', scope);
        for (let toggle of toggles) {
            BatchAssetSelection.toggleCollapse(toggle, true);
        }

        return false;
    },

    hideBlocked: function () {
        const children = $j(this).closest('.batch-selection-scope')
            .find(BatchAssetSelection.blockedSelectors)
            .closest('.batch-selection-asset');
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
        $j(this).closest('.batch-selection-scope')
            .find(BatchAssetSelection.blockedSelectors)
            .closest('.batch-selection-asset').show();

        return false;
    }
}

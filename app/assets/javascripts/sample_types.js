var SampleTypes = {
    recalculatePositions: function () {
        console.log("sorting...");
        $j('#attribute-table tr.sample-attribute .attribute-position').each(function (index, item) {
            $j('.attribute-position-label', $j(item)).html(index + 1);
            $j('input', $j(item)).val(index + 1);
        });
    },

    bindSortable: function () {
        $j('#attribute-table tbody').sortable({
            items: '.sample-attribute',
            helper: SampleTypes.fixHelper,
            handle: '.attribute-handle'
        }).on('sortupdate', function() {
            SampleTypes.recalculatePositions();
        })
    },

    unbindSortable: function () {
        $j('#attribute-table tbody').sortable('destroy');
    },

    fixHelper: function(e, ui) {
        ui.children().each(function () {
            $j(this).width($j(this).width());
        });
        return ui;
    }
};

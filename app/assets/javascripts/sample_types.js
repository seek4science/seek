var SampleTypes = {
    recalculatePositions: function () {
        console.log("sorting...");
        $j('#attribute-table tr.sample-attribute input.attribute-position').each(function (index, item) {
            $j(this).val(index + 1);
        });
    },

    bindSortable: function () {
        $j('#attribute-table tbody').sortable({
            items: '.sample-attribute',
            helper: SampleTypes.fixHelper
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

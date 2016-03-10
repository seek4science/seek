var SampleTypes = {
    recalculatePositions: function () {
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
    },

    removeAttribute: function () {
        var row = $j(this).parents('.sample-attribute');
        if($j(this).is(':checked')) {
            if (row.hasClass('success')) { // If it is a new attribute, just delete from the form - doesn't exist yet.
                row.remove();
                SampleTypes.recalculatePositions();
            } else {
                row.addClass('danger');
                // This selects all the fields in the row, except the magic "_destroy" checkbox
                $j(':input:not(.destroy-attribute)', row).prop('disabled', true);
            }
        }
        else {
            row.removeClass('danger');
            $j(':input:not(.destroy-attribute)', row).prop('disabled', false);
        }
    }
};

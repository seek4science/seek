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

    singleIsTitle: function () {
        if ($j(this).is(':checked')) {
            $j('.sample-type-is-title:not(#'+this.id+')').prop('checked',false);
        }
        else {
            if ($j('.sample-type-is-title:checked').length==0) {
                $j(this).prop('checked',true);
            }
        }
    },

    //make sure there is at least one attribute with title flag checked, particularly after remove
    checkForIsTitle: function() {
        if ($j('.sample-type-is-title:checked').length==0 && $j(".sample-attribute:not(.danger)").length>0) {
            $j(".sample-attribute:not(.danger)").find(".sample-type-is-title")[0].checked=true;
        }
    },

    removeAttribute: function () {
        var row = $j(this).parents('.sample-attribute');
        if($j(this).is(':checked')) {
            if (row.hasClass('success')) { // If it is a new attribute, just delete from the form - doesn't exist yet.
                row.remove();
                SampleTypes.recalculatePositions();
            } else {
                row.addClass('danger');
                // This selects all the fields in the row, except the magic "_destroy" checkbox and the hidden ID field
                $j(':input:not(.destroy-attribute):not([type=hidden])', row).prop('disabled', true);
                row.find('.sample-type-is-title').prop('checked',false);
            }
        }
        else {
            row.removeClass('danger');
            $j(':input:not(.destroy-attribute)', row).prop('disabled', false);
        }
        SampleTypes.checkForIsTitle();
    }


};

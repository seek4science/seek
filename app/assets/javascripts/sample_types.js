var SampleTypes = {
    recalculatePositions: function (selector = "#attribute-table") {
        $j(selector + ' tr.sample-attribute .attribute-position').each(function (index, item) {
            $j('.attribute-position-label', $j(item)).html(index + 1);
            $j('input', $j(item)).val(index + 1);
        });
    },

    bindSortable: function (selector = "#attribute-table") {
        $j(selector + ' tbody').sortable({
            items: '.sample-attribute',
            helper: SampleTypes.fixHelper,
            handle: '.attribute-handle'
        }).on('sortupdate', function() {
            SampleTypes.recalculatePositions();
        });
    },

    unbindSortable: function (selector = "#attribute-table") {
        $j(selector + ' tbody').sortable('destroy');
    },

    fixHelper: function(e, ui) {
        ui.children().each(function () {
            $j(this).width($j(this).width());
        });
        return ui;
    },

    singleIsTitle: function () {
        const attributeTable = $j(this).closest("table")
        if ($j(this).is(':checked')) {
            const selector = attributeTable.find('.sample-type-is-title:not(#'+this.id+')')
            $j(selector).prop('checked',false);
        }
        else {
            if (attributeTable.find('.sample-type-is-title:checked').length==0) {
                $j(this).prop('checked',true);
            }
        }
    },

    //make sure there is at least one attribute with title flag checked, particularly after remove
    checkForIsTitle: function(attributeTable) {
        if (attributeTable.find('.sample-type-is-title:checked').length==0 
            && attributeTable.find(".sample-attribute:not(.danger)").length>0) {
            attributeTable.find(".sample-attribute:not(.danger)").find(".sample-type-is-title")[0].checked=true;
        }
    },

    removeAttribute: function () {
        var row = $j(this).parents('.sample-attribute');
        const attributeTable = $j(this).closest("table")
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
        SampleTypes.checkForIsTitle(attributeTable);
    },

    attributeTypeChanged: function (e, resetSelection=true) {
        //check if it is a controlled vocab, and change the state of the controlled vocab selector if need be
        var use_cv = $j(this).find(':selected').data('use-cv');
				var is_ontology = $j(this).find(':selected').data('is-ontology');
        var cv_element = $j(this).siblings('.controlled-vocab-block');
        if (use_cv) {
					var cv_selection = cv_element.find('.controlled-vocab-selection');
					cv_selection.find('option').show();
					cv_selection.find(`option[data-is-ontology="${!is_ontology}"]`).hide();
					if (resetSelection) cv_selection.find('option:selected').prop("selected", false);
          cv_element.show();
        }
        else {
            cv_element.hide();
        }

        var is_seek_sample = $j(this).find(':selected').data('is-seek-sample');
        var seek_sample_element = $j(this).siblings('.sample-type-block');
        if (is_seek_sample) {
            seek_sample_element.show();
            const is_seek_sample_multi = $j(this).find(':selected').text() == "SEEK Sample Multi"
            if(is_seek_sample_multi) {
                $j(this).closest(".sample-attribute").find(".sample-type-is-title")
                    .prop('checked', false).attr("disabled", true)
            }
        }
        else {
            seek_sample_element.hide();
        }
    }

};

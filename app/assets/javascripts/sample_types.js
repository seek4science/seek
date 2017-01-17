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
        });
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
    },

    attributeTypeChanged: function () {
        //check if it is a controlled vocab, and change the state of the controlled vocab selector if need be
        var is_cv = $j(this).find(':selected').data('is-cv');
        var cv_element = $j(this).siblings('.controlled-vocab-block');
        if (is_cv) {
            cv_element.show();
        }
        else {
            cv_element.hide();
        }

        var is_seek_sample = $j(this).find(':selected').data('is-seek-sample');
        var seek_sample_element = $j(this).siblings('.sample-type-block');
        if (is_seek_sample) {
            seek_sample_element.show();
        }
        else {
            seek_sample_element.hide();
        }
    }

};

var SampleTypeControlledVocab = {
    controlledVocabSelectionTagId: "",
    blankControlledVocabModelForm: null,

    //binds the show event to the modal dialogue, for determining which button, and therefore dropdown selection, is linked
    //to the form
    bindNewControlledVocabShowEvent: function () {
        $j('#cv-modal').on('show.bs.modal', function (event) {
            var button = $j(event.relatedTarget); // Button that triggered the modal
            var dropdown = button.siblings('select');
            SampleTypeControlledVocab.controlledVocabSelectionTagId = (dropdown.prop('id'));
        });
    },

    //the select element associated with the last New button pressed
    controlledVocabSelectionElement: function() {
        return $j('#'+SampleTypeControlledVocab.controlledVocabSelectionTagId);
    },

    //resets the modal
    resetModalControlledVocabForm: function () {
        $j('#cv-modal').remove();
        $j('#modal-dialogues').append(SampleTypeControlledVocab.blankControlledVocabModelForm.clone());
        initialiseCVForm();
        SampleTypeControlledVocab.bindNewControlledVocabShowEvent();
    },

    //selected CV item changed
    controlledVocabChanged: function() {
        var id=$j(this).find(':selected')[0].value;
        var editable=$j(this).find(':selected').data('editable');
        var link='/sample_controlled_vocabs/'+id+'/edit';
        var button=$j(this).siblings('.cv-edit-button');
        if (editable) {
            button.show();
            button.attr('disabled',false);
        }
        else {
            button.show();
            button.attr('disabled',true);
        }
        button.prop('href',link);
    }
};

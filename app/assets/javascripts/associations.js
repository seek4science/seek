function optionsFromArray(array) {
    var options = [];

    for(var i = 0; i < array.length; i++)
        options.push($j('<option/>').val(array[i][1]).text(array[i][0])[0]);

    return options;
}

var associations = {
    toggleEmptyListText: function (list) {
        var noText = $j('.no-item-text', list);

        if($j('.association-list-item', list).length == 0)
            noText.show();
        else
            noText.hide();
    }
};

$j(document).ready(function () {
    $j('body').on('click', '.association-preview', function () {
        $j(this).siblings().removeClass('active');
        $j(this).addClass('active');
        return false;
    });

    $j('[data-role="seek-associations-list"]').each(function () {
        var self = $j(this);
        var existingValues = JSON.parse($j('script[data-role="seek-existing-associations"]', self).html());

        var template = HandlebarsTemplates[self.data('templateName')];
        var ulElement = $j('ul', self);

        existingValues.each(function (value) {
            ulElement.append(template(value));
        });
        associations.toggleEmptyListText(self);

        $j(this).on('click', '.remove-association', function () {
            $j(this).parent().remove();
            associations.toggleEmptyListText(self);
        });

    });

    $j('[data-role="seek-confirm-association-button"]').click(function (e) {
        e.preventDefault();
        var modal = $j(this).parents('.new-association-modal');
        var associationObject = {
            id: $j('.association-preview.active', modal).data('associationId'),
            title: $j('.association-preview.active', modal).data('associationTitle')
        };

        // Build a JSON object from the inputs in the modal
        $j(':input', modal).each(function (_, input) {
            if($j(input).attr('name')) {
                var name = $j(input).attr('name').replace('_association_','');
                associationObject[name] = $j(this).val();
            }
        });

        var list = $j('#'+$j(this).data('associationsListId'));
        var template = HandlebarsTemplates[list.data('templateName')];
        list.find('ul').append(template(associationObject));
        associations.toggleEmptyListText(list);

        modal.modal('hide');
        return false;
    });

    $j('.association-filter').keypress(function (e) {
        // If more than two characters were entered, or the input was cleared, or the ENTER key was pressed..
        if($j(this).val().length == 0 || $j(this).val().length >= 2 || e.keyCode == 13) {
            var modal = $j(this).parents('.new-association-modal');
            $j.ajax($j(this).data('filterUrl'), {
                    data: { filter: $j(this).val() },
                    success: function (data) { $j('.association-candidate-list', modal).html(data); }
                }
            );
            if(e.keyCode == 13)
                e.preventDefault();
        }
    });
});

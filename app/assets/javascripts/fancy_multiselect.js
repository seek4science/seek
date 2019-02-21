$j(document).ready(function () {
    $j('[data-role="seek-fancy-multiselect"] select[data-associations-list-id]').change(function () {
        var listElement = $j('#' + $j(this).data('associationsListId'));
        var listObject = listElement.data('associationList');
        var selectedOption = $j('option:selected', $j(this));
        if (!selectedOption.val()) {
            return;
        }
        var item = { id: parseInt(selectedOption.val()),
            title: selectedOption.text() };

        // Load preview
        if ($j(this).data('previewUrl')) {
            $j.get($j(this).data('previewUrl'), { id: item.id });
        }

        if (!listObject.exists(function (i) { return i.id === item.id })) {
            listObject.add(item);
        } else {
            // Highlight existing item if its already there
            $j('[value=' + item.id + ']', listElement).parent().highlight('blue');
        }
    });
});

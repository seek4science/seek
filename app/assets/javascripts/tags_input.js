$j(document).ready(function () {
    $j('[data-role="seek-tagsinput"]').each(function () {

        var opts = {
            placeholder: 'Search ...',
            theme: "bootstrap",
            tags: true
        };

        if ($j(this).data('tags-limit')) {
            opts.maximumSelectionLength = $j(this).data('tags-limit');
        }

        if ($j(this).data('typeahead-local-values')) {
            console.log($j(this).data('typeahead-local-values'));
            opts.data = $j(this).data('typeahead-local-values');
        }

        if ($j(this).data('typeahead-query-url')) {
            opts.ajax={
                url: $j(this).data('typeahead-query-url'),
                dataType: 'json'
            }
        }

        $j(this).select2(
            opts
        );

    });

    $j('[data-role="seek-suggested-tags"]').on('click', function () {
        let selectName = $j(this).data('tag-input');
        let text = $j(this).text();
        let selector = $j('select#'+selectName);
        let vals = selector.val() || [];
        vals.push(text);
        selector.val(vals);
        selector.change();
        return false;
    });

});
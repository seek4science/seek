$j(document).ready(function () {
    $j('[data-role="seek-objectsinput"]').each(function () {

        var opts = {
            placeholder: 'Search ...',
            theme: "bootstrap",
            width: '100%'
        };

        if ($j(this).data('placeholder')) {
            opts.placeholder = $j(this).data('placeholder');
        }

        if ($j(this).data('tags-limit')) {
            opts.maximumSelectionLength = $j(this).data('tags-limit');
        }

        if ($j(this).data('allow-new-items')) {
            opts.tags = $j(this).data('allow-new-items')
        }

        if ($j(this).data('typeahead-local-values')) {
            opts.data = $j(this).data('typeahead-local-values');
        }

        var template = $j(this).data('typeahead-template') || 'typeahead/hint';
        opts.templateResult = HandlebarsTemplates[template];
        opts.escapeMarkup = function (m) {
            return m;
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

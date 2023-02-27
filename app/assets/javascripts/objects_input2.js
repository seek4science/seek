$j(document).ready(function () {
    $j('[data-role="seek-objectsinput2"]').each(function () {

        var opts = {
            placeholder: 'Search ...',
            theme: "bootstrap",
            tags: true
        };


        if ($j(this).data('tags-limit')) {
            opts.maximumSelectionLength = $j(this).data('tags-limit');
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
});
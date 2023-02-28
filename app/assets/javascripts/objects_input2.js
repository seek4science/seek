$j(document).ready(function () {
    $j('[data-role="seek-objectsinput2"]').each(function () {

        var opts = {
            placeholder: 'Search ...',
            theme: "bootstrap"
        };


        if ($j(this).data('tags-limit')) {
            opts.maximumSelectionLength = $j(this).data('tags-limit');
        }

        if ($j(this).data('allow-new-items')) {
            opts.tags = $j(this).data('allow-new-items')
        }

        var template = $j(this).data('typeahead-template') || 'typeahead/hint';
        template = 'typeahead/institution'
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
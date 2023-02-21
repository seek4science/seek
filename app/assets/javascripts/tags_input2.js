$j(document).ready(function () {
    $j('[data-role="seek-tagsinput2"]').each(function () {

        var opts = {
            placeholder: 'Search ...',
            theme: "bootstrap",
            tags: true
        };

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
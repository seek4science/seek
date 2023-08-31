var ObjectsInput = {

    init: function(element) {
        (element?.item || $j('[data-role="seek-objectsinput"]')).each(function () {

            //skip if already initialised
            if ($j(this).data('select2')) {
                return true;
            }

            const opts = {
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

            const template = $j(this).data('typeahead-template') || 'typeahead/hint';
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
    }
}
$j(document).ready(function () {

    ObjectsInput.init();

    $j('[data-role="seek-suggested-tags"]').on('click', function () {
        const selectName = $j(this).data('tag-input');
        const text = $j(this).text();
        const selector = $j('select#'+selectName);
        const vals = selector.val() || [];
        vals.push(text);
        selector.val(vals);
        selector.change();
        return false;
    });
});

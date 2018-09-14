$j(document).ready(function () {
    $j('[data-tooltip]').popover({
        html: false,
        animation: false,
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        content: function () {
            return $j(this).data('tooltip');
        }
    });

    $j('label.required, span.required').popover({
        html: false,
        animation: false,
        delay: {
            show: 500,
            hide: 100
        },
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        content: 'This field is required.'
    });
});

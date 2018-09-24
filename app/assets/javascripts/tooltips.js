$j(document).ready(function () {
    bindTooltips('body');

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

function bindTooltips(root_tag) {
    $j(root_tag + ' [data-tooltip]').popover({
        html: false,
        animation: false,
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        delay: {
            show: 500,
            hide: 100
        },
        content: function () {
            return $j(this).data('tooltip');
        }
    });
};




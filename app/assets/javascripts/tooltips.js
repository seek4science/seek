$j(document).ready(function () {
    $j('[data-tooltip]').popover({
        html: true,
        animation: false,
        trigger: 'hover',
        placement: 'auto right',
        container: 'body',
        content: function () {
            return $j(this).data('tooltip');
        }
    });
});

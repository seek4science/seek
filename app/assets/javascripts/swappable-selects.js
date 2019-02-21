$j(document).ready(function () {
    $j('[data-role="seek-swappable-select-toggle"]').change(function () {
        var group = $j(this).parents('[data-role="seek-swappable-select-group"]');
        var select = $j('[data-role="seek-swappable-select"]', group);
        var alt = $j('[data-role="seek-swappable-select-alt"]', group);

        var temp = select.html();
        select.html(alt.html());
        alt.html(temp);
    });
});

$j(document).ready(function () {
    $j('[data-protected-settings-block]').each(function () {
        var block = $j(this);
        $j(':input', block).prop('disabled', true);

        var btn = $j('<a href="#" class="btn btn-default btn-xs">Unlock settings</a>');
        var locked = true;
        btn.click(function () {
            locked = !locked
            $j(':input', block).prop('disabled', locked);
            btn.text((locked ? 'Unlock' : 'Lock') + ' settings');
            return false;
        });

        block.prepend(btn);
    });
});

$j(document).ready(function () {
    $j('[data-role="seek-tagsinput2"]').each(function () {

        $j(this).select2(
            {
                placeholder: 'Search ...',
                theme: "bootstrap"
            }
        );

    });
});
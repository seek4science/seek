// From: https://gist.github.com/fzaninotto/b67783284c5eaa21815c#file-gistfile1-js
$j(document).ready(function() {
    // add a hash to the URL when the user clicks on a tab
    $j('a[data-toggle="tab"]').on('click', function(e) {
        history.pushState(null, null, $j(this).attr('href'));
    });
    // navigate to a tab when the history changes
    window.addEventListener("popstate", showTabFromHistory);
    // Above callback won't be triggered if page was reloaded, so:
    showTabFromHistory();
});

function showTabFromHistory() {
    if(location.hash) {
        var activeTab = $j('[href="' + location.hash + '"]');
        if (activeTab.length) {
            activeTab.tab('show');
            // Go through the parent tabs that contain this tab and ensure they are opened.
            activeTab.parents('.tab-pane').each(function () {
                var pane = $j(this);
                [$j('[data-toggle="tab"][href="#' + pane.attr('id') + '"]'),
                 $j('[data-toggle="tab"][data-target="#' + pane.attr('id') + '"]')].forEach(function (selector) {
                     if (selector.length) {
                        selector.tab('show');
                     }
                });
            });
        } else {
            $j('.nav-tabs a:first').tab('show');
        }
    }
}

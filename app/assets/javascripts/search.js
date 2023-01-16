var Search = {
    disableBlankElements: function (state) {
        // :input will select all form-related tags (input, select, button etc.)
        $j('#advanced-search :input').filter(function () {
            return $j(this).val() == '';
        }).each(function () {
            $j(this).prop('disabled', state);
        });
        $j('#adv-search-button').prop('disabled', false); // Don't disable this!
    },

    toggleAdvanced: function () {
        $j('#advanced-search').toggle();
        // Ensure form elements are all enabled. User might have clicked back button
        Search.disableBlankElements(false);
    }
};

$j(document).ready(function () {
    $j('#adv-search-btn').click(Search.toggleAdvanced);

    $j('#search-form').submit(function () {
        // Hide advanced panel
        var panel = $j('#advanced-search');
        if(panel.is(':visible')) {
            panel.hide();
            $j('#adv-search-btn').button('toggle');
        }
        Search.disableBlankElements(true);
        return true;
    });
});

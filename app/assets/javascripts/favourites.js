var closeDropdownWhenDone = false;

$j(document).ready(function () {

    $j("#add-favourites-zone").droppable({
        //activeClass: "ui-state-default",
        //hoverClass: "ui-state-hover",
        accept: ".favouritable",
        drop: function(event, ui) {
            $j('#fav_ajax-loader').show();
            $j.post(ui.draggable.data('favouriteUrl'))
                .done(function (data) { $j('#favourite_list').html(data); $j("#add-favourites-zone").highlight('success'); })
                .fail(function () { $j("#add-favourites-zone").highlight('danger'); })
                .always(function() { $j('#fav_ajax-loader').hide(); });
        }
    });

    $j("#delete-favourite-zone").droppable({
        greedy: true,
        accept: ".favourite",
        drop: function(event, ui) {
            $j('#fav_ajax-loader').show();
            $j.ajax({
                url: ui.draggable.data('deleteUrl'),
                type: 'DELETE'
            })
                .done(function (data) { $j('#favourite_list').html(data); $j("#add-favourites-zone").highlight('success'); })
                .fail(function () { $j("#add-favourites-zone").highlight('danger'); })
                .always(function() { $j('#fav_ajax-loader').hide(); });
        }
    });

    bindFavouritables($j('.favouritable'));
    bindFavourites($j('.favourite'));
});

function bindFavouritables(elements) {
    elements.draggable({
        revert: true,
        appendTo: 'body',
        start: function () {
            if (!$j('#user-menu').hasClass('open')) {
                closeDropdownWhenDone = true;
                $j('#user-menu-button').dropdown('toggle');
            } else {
                closeDropdownWhenDone = false;
            }
            $j('#add-favourites-zone').addClass('active');
            $j('#add-favourites-zone-text').show();
        },
        stop: function () {
            $j('#add-favourites-zone').removeClass('active');
            $j('#add-favourites-zone-text').hide();
            if(closeDropdownWhenDone)
                setTimeout(function () {
                    if ($j('#user-menu').hasClass('open'))
                        $j('#user-menu-button').dropdown('toggle');
                }, 800);
        }
    });
}

function bindFavourites(elements) {
    elements.draggable({
        revert: true,
        appendTo: 'body',
        start: function () {
            $j('#delete-favourite-zone').fadeIn();
        },
        stop: function () {
            $j('#delete-favourite-zone').hide();
        }
    });
}

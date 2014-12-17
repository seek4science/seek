// Script to open the user dropdown menu when a favouritable icon is dragged, and highlight the appropriate 'drop zone'

var draggedFavourite = false;
var draggedFavouritable = false;

$j(document).ready(function () {
    $j('.favouritable').mousedown(handleFavouritableDrag);

    $j(document).mouseup(function (e) {
        if(draggedFavourite) {
            $j('#delete-favourite-zone').hide();
        }
        if(draggedFavouritable) {
            $j('#drop_favourites').removeClass('active');
            $j('#drop-favourite-text').hide();
        }
    });

    $j("#user-menu").on("hide.bs.dropdown",function(e) {
        // After dragging a favouritable icon, wait a bit before closing the user menu
        if(draggedFavouritable) {
            e.stopPropagation();
            draggedFavouritable = false;
            setTimeout(function () {
                if(!draggedFavouritable && $j('#user-menu').hasClass('open'))
                    $j('#user-menu-button').dropdown('toggle');
            }, 800);
            return false;
        }
        // Don't automatically close the menu when dragging an existing favourite, as it wasn't opened automatically
        if(draggedFavourite) {
            e.stopPropagation();
            draggedFavourite = false;
            return false;
        }
    });
});

var handleFavouritableDrag = function (e) {
    var userMenu = $j('#user-menu');
    var userMenuButton = $j('#user-menu-button');
    var deleteFavouriteZone = $j('#delete-favourite-zone');
    var addFavouriteZone = $j('#drop_favourites');
    var dropFavouritesText = $j('#drop-favourite-text');

    if($j(this).hasClass('favourite')) { // Show delete section if its already a favourite
        deleteFavouriteZone.fadeIn();
        draggedFavourite = true;
    } else { // Otherwise open the user menu to expose the drop zone
        if(!userMenu.hasClass('open'))
            userMenuButton.dropdown('toggle');
        addFavouriteZone.addClass('active');
        dropFavouritesText.show();
        draggedFavouritable = true;
    }
};

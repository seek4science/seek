function update_menu_text(source_id,fadein) {
    var sections = $('section_menu_items');
    var source = $(source_id);
    if (fadein) {
        sections.hide();
    }
    sections.update(source.innerHTML);
    if (fadein) {
        Effect.Appear('section_menu_items',{duration:0.3});
    }
}

function select_menu_item(section_id) {
    update_menu_text(section_id,false);
}


// handle the width of the search box according to the width of the screen
Event.observe(window,"resize", function() {
    set_searchbox_width();
});
document.observe("dom:loaded",function() {
    set_searchbox_width();
});

function set_searchbox_width() {
    search_query = $("search_query");
    if (search_query != null){
        if (document.viewport.getWidth()<=1199) {
            search_query.style.width="15em";
        }
        else {
            search_query.style.width="26em";
        }
        search_query.show();
    }
}

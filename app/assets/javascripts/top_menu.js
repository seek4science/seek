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

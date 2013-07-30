function update_menu_text(source_id) {
    var sections = $('section_menu_items');
    var source = $(source_id);
    sections.hide();
    sections.update(source.innerHTML);
    Effect.Appear('section_menu_items',{duration:0.3});
}

function select_menu_item(section_id) {
    update_menu_text(section_id);
}
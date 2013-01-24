function showOrHideButtonBox() {
    if (document.getElementsByClassName('mainButtons')[0].children.length == 0) {
        $('main_content_button_box').style['display'] = 'none';
        $('main_content_left_box_narrower').style['width'] = '73%';
    }
}
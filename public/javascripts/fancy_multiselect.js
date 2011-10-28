    function addSelectedToFancy(multiselect, value) {
        if (!$F(multiselect).include(value)) {
            $(multiselect).setValue($F(multiselect).concat(value));
            updateFancyMultiselect(multiselect);
        } else {
            alert('Item already exists!');
        }
    }

    function removeFromFancy(multiselect, value) {
        $(multiselect).setValue($F(multiselect).without(value));
        updateFancyMultiselect(multiselect);
    }

    function insertFancyListItem(multiselect, displaylist, option) {
        var title_span = '<span title="' + option.text + '">' + option.text.truncate(100) + '</span>';
        var remove_link = '<a href="" onclick="javascript:removeFromFancy(';
        remove_link += "'" + $(multiselect).id + "','";
        remove_link += option.value + "'";
        remove_link += '); return(false);">remove</a>';
        displaylist.insert('<li>' + title_span +'&nbsp;&nbsp;<small style="vertical-align: middle;">[' + remove_link + ']</small></li>');
    }

    function updateFancyMultiselect(multiselect) {
        multiselect = $(multiselect);
        var display_area = $(multiselect.id + '_display_area');
        var selected_options = multiselect.childElements().select(function(c){return c.selected});
        if(selected_options.length > 0) {
            display_area.innerHTML = '<ul class="related_asset_list"></ul>'
            var list = display_area.select('ul')[0];
            selected_options.each(function(opt){
                insertFancyListItem(multiselect, list, opt);
            });
        } else {
            display_area.innerHTML = '<span class="none_text">None</span>';
        }
        multiselect.fire('fancySelect:update');
    }

    function swapSelectListContents(target, alternative) {
        var old = $(target).innerHTML;
        $(target).innerHTML = $(alternative).innerHTML;
        $(alternative).innerHTML = old;
    }
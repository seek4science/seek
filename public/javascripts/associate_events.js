var events_array = new Array();
function check_show_add_event() {
    i = $('possible_events').selectedIndex;
    selected_id = $('possible_events').options[i].value;
    if (selected_id == '0') {
        $('add_event_link').hide();
    }
    else {
        $('add_event_link').show();
    }
}

function addSelectedEvent() {
    selected_option_index = $("possible_events").selectedIndex;
    selected_option = $("possible_events").options[selected_option_index];
    title = selected_option.text;
    id = selected_option.value;

    if (checkNotInList(id, events_array)) {
        events_array.push([title,id]);
        updateEvents();
    }
    else {
        alert('The following Event had already been added:\n\n' +
                title);
    }
}

function updateEvents() {
    event_text = '<ul class="related_asset_list">'
    for (var i = 0; i < events_array.length; i++) {
        var event = events_array[i];
        var title = event[0];
        var id = event[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        event_text += '<li>' + titleText +
                '&nbsp;&nbsp;<small style="vertical-align: middle;">'
                + '[<a href="" onclick="javascript:events_array.splice(' + i + ', 1);updateEvents(); return(false);">remove</a>]</small></li>';
    }

    event_text += '</ul>';

    // update the page
    if (events_array.length == 0) {
        $('event_to_list').innerHTML = '<span class="none_text">No Event</span>';
    }
    else {
        $('event_to_list').innerHTML = event_text;
    }

    clearList('event_ids');

    select = $('event_ids');
    for (i = 0; i < events_array.length; i++) {
        id = events_array[i][1];
        o = document.createElement('option');
        o.value = id;
        o.text = id;
        o.selected = true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o, null);
        }
    }
}
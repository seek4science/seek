var sops=new Array();

function addSop(title,id) {
    sops.push([title,id])
}

function postTopicData() {
    request = new Ajax.Request(CREATE_TOPIC_LINK,
    {
        method: 'post',
        parameters: {
            id: $('topic_id').value,  // empty ID will be submitted on "create" action, but it doesn't make a difference
            title: $('title').value,
            project_id: $('project_id').value
        },
        onSuccess: function(transport){
            var data = transport.responseText.evalJSON(true);
            if (data.status==200){                
                addNewTopic(data.new_topic);
            }
            RedBox.close();
            return (true);
        },
        onFailure: function(transport){
            alert('Something went wrong, please try again...');
            return(false);
        }
    });

}

function addNewTopic(new_topic) {    
    selectObj=$('topic_id');
    selectObj.options[select.options.length]=new Option(new_topic[1],new_topic[0],false,true);
    selectObj.disabled=false;
    selectObj.onchange();
}

function addSelectedSop() {
    selected_option_index=$("possible_sops").selectedIndex
    selected_option=$("possible_sops").options[selected_option_index]
    title=selected_option.text
    id=selected_option.value

    if(checkSopNotInList(id)) {
        addSop(title,id);
        updateSops();
    }
    else {
        alert('The following Sop had already been added:\n\n' +
            title);
    }
}

function checkSopNotInList(sop_id) {
    rtn = true;
  
    for(var i = 0; i < sops.length; i++)
        if(sops[i][1] == sop_id) {
            rtn = false;
            break;
        }
  
    return(rtn);
}

function deleteSop(id) {
    // remove the actual record for the attribution
    for(var i = 0; i < sops.length; i++)
        if(sops[i][1] == id) {
            sops.splice(i, 1);
            break;
        }

    // update the page
    updateSops();
}

function updateSops() {
    sop_text=''
    type="Sop"
    sop_ids=new Array();

    for (var i=0;i<sops.length;i++) {
        sop=sops[i]
        title=sop[0]
        id=sop[1]        
        sop_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:deleteSop('+id+'); return(false);">delete</a>]</small><br/>';
        sop_ids.push(id)
    }

    // remove the last line break
    if(sop_text.length > 0) {
        sop_text = sop_text.slice(0,-5);
    }

    // update the page
    if(sop_text.length == 0) {
        $('sop_to_list').innerHTML = '<span class="none_text">No sops</span>';
    }
    else {
        $('sop_to_list').innerHTML = sop_text;
    }

    clearSopList();

    select=$('experiment_sop_ids')
    for (i=0;i<sop_ids.length;i++) {
        id=sop_ids[i]
        o=document.createElement('option')
        o.value=id
        o.text=id
        o.selected=true
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }        
    }
}

function clearSopList() {
    select=$('experiment_sop_ids')
    while(select.length>0) {
        select.remove(select.options[0])
    }
}
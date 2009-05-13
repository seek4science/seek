var sops=new Array();
var assays=new Array();
var data_files=new Array();

function postInvestigationData() {
    request = new Ajax.Request(CREATE_INVESTIGATION_LINK,
    {
        method: 'post',
        parameters: {
            id: $('study_investigation_id').value,  // empty ID will be submitted on "create" action, but it doesn't make a difference
            title: $('title').value,
            project_id: $('project_id').value
        },
        onSuccess: function(transport){
            var data = transport.responseText.evalJSON(true);
            
            if (data.status==200){                
                addNewInvestigation(data.new_investigation);
                RedBox.close();
            }
            if (data.status==406) {
                $('errorExplanation').innerHTML=data.error_messages;
                $('errorExplanation').show();
            }
            
            return (true);
        },
        onFailure: function(transport){            
            alert('Something went wrong, please try again...');
            return(false);
        }
    });

}

function addNewInvestigation(new_investigation) {
    selectObj=$('study_investigation_id');
    selectObj.options[select.options.length]=new Option(new_investigation[1],new_investigation[0],false,true);
    selectObj.disabled=false;    
}

function addSop(title,id) {
    sops.push([title,id])
}

function addSelectedSop() {
    selected_option_index=$("possible_sops").selectedIndex
    selected_option=$("possible_sops").options[selected_option_index]
    title=selected_option.text
    id=selected_option.value

    if(checkNotInList(id,sops)) {
        addSop(title,id);
        updateSops();
    }
    else {
        alert('The following Sop had already been added:\n\n' +
            title);
    }
}

function removeSop(id) {
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
        + '[<a href="" onclick="javascript:removeSop('+id+'); return(false);">remove</a>]</small><br/>';
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

    clearList('assay_sop_ids');

    select=$('assay_sop_ids')
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

//Data files
function addDataFile(title,id) {
    data_files.push([title,id])
}

function addSelectedDataFile() {
    selected_option_index=$("possible_data_files").selectedIndex
    selected_option=$("possible_data_files").options[selected_option_index]
    title=selected_option.text
    id=selected_option.value

    if(checkNotInList(id,data_files)) {
        addDataFile(title,id);
        updateDataFiles();
    }
    else {
        alert('The following Data file had already been added:\n\n' +
            title);
    }
}

function removeDataFile(id) {
    // remove the actual record for the attribution
    for(var i = 0; i < data_files.length; i++)
        if(data_files[i][1] == id) {
            data_files.splice(i, 1);
            break;
        }

    // update the page
    updateDataFiles();
}

function updateDataFiles() {
    data_file_text=''
    type="DataFile"
    data_file_ids=new Array();

    for (var i=0;i<data_files.length;i++) {
        data_file=data_files[i]
        title=data_file[0]
        id=data_file[1]
        data_file_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeDataFile('+id+'); return(false);">remove</a>]</small><br/>';
        data_file_ids.push(id)
    }

    // remove the last line break
    if(data_file_text.length > 0) {
        data_file_text = data_file_text.slice(0,-5);
    }

    // update the page
    if(data_file_text.length == 0) {
        $('data_file_to_list').innerHTML = '<span class="none_text">No data files</span>';
    }
    else {
        $('data_file_to_list').innerHTML = data_file_text;
    }

    clearList('data_file_ids');

    select=$('data_file_ids')
    for (i=0;i<data_file_ids.length;i++) {
        id=data_file_ids[i]
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



//Assays
function addSelectedAssay() {
    selected_option_index=$("possible_assays").selectedIndex
    selected_option=$("possible_assays").options[selected_option_index]
    title=selected_option.text
    id=selected_option.value

    if(checkNotInList(id,assays)) {
        addAssay(title,id);
        updateAssays();
    }
    else {
        alert('The following Assay had already been added:\n\n' +
            title);
    }
}

function removeAssay(id) {
    // remove the actual record for the attribution
    for(var i = 0; i < assays.length; i++)
        if(assays[i][1] == id) {
            assays.splice(i, 1);
            break;
        }

    // update the page
    updateAssays();
}

function updateAssays() {
    assay_text=''
    type="Assay"
    assay_ids=new Array();

    for (var i=0;i<assays.length;i++) {
        assay=assays[i]
        title=assay[0]
        id=assay[1]
        assay_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeAssay('+id+'); return(false);">remove</a>]</small><br/>';
        assay_ids.push(id)
    }

    // remove the last line break
    if(assay_text.length > 0) {
        assay_text = assay_text.slice(0,-5);
    }

    // update the page
    if(assay_text.length == 0) {
        $('assay_to_list').innerHTML = '<span class="none_text">No assays</span>';
    }
    else {
        $('assay_to_list').innerHTML = assay_text;
    }

    clearList('study_assay_ids');

    select=$('study_assay_ids')
    for (i=0;i<assay_ids.length;i++) {
        id=assay_ids[i]
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

function addAssay(title,id) {
    assays.push([title,id])
}
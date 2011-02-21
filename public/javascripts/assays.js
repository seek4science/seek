var sops_assets=new Array();
var models_assets=new Array();
var assays=new Array();
var data_files_assets=new Array();
var publications_array = new Array();
var organisms = new Array();

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
    sops_assets.push([title,id]);
}

function addSelectedSop() {
    selected_option_index=$("possible_sops").selectedIndex;
    selected_option=$("possible_sops").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

    if(checkNotInList(id,sops_assets)) {
        addSop(title,id);
        updateSops();
    }
    else {
        alert('The following Sop had already been added:\n\n' +
            title);
    }
}

function removeSop(index) {
    sops_assets.splice(index, 1);
    // update the page
    updateSops();
}

function updateSops() {
    sop_text='<ul class="related_asset_list">';

    sop_ids=new Array();

    for (var i=0;i<sops_assets.length;i++) {
        sop=sops_assets[i];
        title=sop[0];
        id=sop[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        sop_text += '<li>' + titleText + 
          '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">' +
          '[<a href=\"\" onclick=\"javascript:removeSop('+i+'); return(false);\">remove</a>]</small></li>';
        sop_ids.push(id);
    }
    
    sop_text += '</ul>';

    // update the page
    if(sops_assets.length == 0) {
        $('sop_to_list').innerHTML = '<span class="none_text">No sops</span>';
    }
    else {
        $('sop_to_list').innerHTML = sop_text;
    }

    clearList('assay_sop_ids');

    select=$('assay_sop_ids')
    for (i=0;i<sop_ids.length;i++) {
        id=sop_ids[i];
        o=document.createElement('option');
        o.value=id;
        o.text=id;
        o.selected=true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }        
    }
}

//Data files
function addDataFile(title,id,relationshipType) {
    data_files_assets.push([title,id,relationshipType]);
}

function addSelectedDataFile() {
    selected_option_index=$("possible_data_files").selectedIndex;
    selected_option=$("possible_data_files").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;
    if ($("data_file_relationship_type")) {
        relationshipType = $("data_file_relationship_type").options[$("data_file_relationship_type").selectedIndex].text;
    }
    else
    {
        relationshipType="None"
    }

    if(checkNotInList(id,data_files_assets)) {
        addDataFile(title,id,relationshipType);
        updateDataFiles();
    }
    else {
        alert('The following Data file had already been added:\n\n' +
            title);
    }
}

function removeDataFile(index) {
    data_files_assets.splice(index, 1);
    // update the page
    updateDataFiles();
}

function updateDataFiles() {
    data_file_text='<ul class="related_asset_list">'
    
    for (var i=0;i<data_files_assets.length;i++) {        
        data_file=data_files_assets[i];
        title=data_file[0];
        id=data_file[1];
        relationshipType = data_file[2];
        relationshipText = (relationshipType == 'None') ? '' : ' <span class="assay_item_sup_info">(' + relationshipType + ')</span>';
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        data_file_text += '<li>' + titleText + relationshipText +
        '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeDataFile('+i+'); return(false);">remove</a>]</small></li>';
    }
    
    data_file_text += '</ul>';

    // update the page
    if(data_files_assets.length == 0) {
        $('data_file_to_list').innerHTML = '<span class="none_text">No data files</span>';
    }
    else {
        $('data_file_to_list').innerHTML = data_file_text;
    }

    clearList('data_file_ids');

    select=$('data_file_ids');
    for (i=0;i<data_files_assets.length;i++) {
        id=data_files_assets[i][1];
        relationshipType=data_files_assets[i][2];
        o=document.createElement('option');
        o.value=id + "," + relationshipType;
        o.text=id;
        o.selected=true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}

//Models
function addModel(title,id) {
    models_assets.push([title,id]);
}

function addSelectedModel() {
    selected_option_index=$("possible_models").selectedIndex;
    selected_option=$("possible_models").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

    if(checkNotInList(id,models_assets)) {
        addModel(title,id);
        updateModels();
    }
    else {
        alert('The following Model had already been added:\n\n' +
            title);
    }
}

function removeModel(index) {
    models_assets.splice(index, 1);
    
    // update the page
    updateModels();
}

function updateModels() {
    model_text='<ul class="related_asset_list">';
    type="Model";
    model_ids=new Array();

    for (var i=0;i<models_assets.length;i++) {
        model=models_assets[i];
        title=model[0];
        id=model[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        model_text += '<li>' + titleText
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeModel('+i+'); return(false);">remove</a>]</small></li>';
        model_ids.push(id);
    }
    
    model_text += '</ul>';

    // update the page
    if(models_assets.length == 0) {
        $('model_to_list').innerHTML = '<span class="none_text">No models</span>';
    }
    else {
        $('model_to_list').innerHTML = model_text;
    }

    clearList('assay_model_ids');

    select=$('assay_model_ids');
    for (i=0;i<model_ids.length;i++) {
        id=model_ids[i];
        o=document.createElement('option');
        o.value=id;
        o.text=id;
        o.selected=true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }        
    }

    if (models_assets.length>=1) {
        Effect.Fade("add_model_elements");
    }
    else {
        Effect.Appear("add_model_elements");
    }
}


//Assays
function addSelectedAssay() {
    selected_option_index=$("possible_assays").selectedIndex;
    selected_option=$("possible_assays").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;

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
    assay_text='';
    type="Assay";
    assay_ids=new Array();

    for (var i=0;i<assays.length;i++) {
        assay=assays[i];
        title=assay[0];
        id=assay[1];
        assay_text += '<b>' + type + '</b>: ' + title
        //+ "&nbsp;&nbsp;<span style='color: #5F5F5F;'>(" + contributor + ")</span>"
        + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
        + '[<a href="" onclick="javascript:removeAssay('+id+'); return(false);">remove</a>]</small><br/>';
        assay_ids.push(id);
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

    select=$('study_assay_ids');
    for (i=0;i<assay_ids.length;i++) {
        id=assay_ids[i];
        o=document.createElement('option');
        o.value=id;
        o.text=id;
        o.selected=true;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}

function addAssay(title,id) {
    assays.push([title,id]);
}

function addOrganism(title,id,strain,culture_growth) {
    organisms.push([title,id,strain,culture_growth]);
}

function addSelectedOrganism() {
    selected_option_index=$("possible_organisms").selectedIndex;
    selected_option=$("possible_organisms").options[selected_option_index];
    title=selected_option.text;
    id=selected_option.value;
    strain=$('strain').value

    selected_option_index=$('culture_growth').selectedIndex;
    selected_option=$('culture_growth').options[selected_option_index];
    culture_growth=selected_option.text    
    
    addOrganism(title,id,strain,culture_growth);
    updateOrganisms();
    
}

function removeOrganism(index) {
    // remove according to the index
    organisms.splice(index, 1);
    // update the page
    updateOrganisms();
}

function updateOrganisms() {
    organism_text='<ul class="related_asset_list">';    

    for (var i=0;i<organisms.length;i++) {
        organism=organisms[i];
        title=organism[0];
        id=organism[1];
        strain=organism[2]
        culture_growth=organism[3]
        titleText = '<span title="' + title + '">' + title.truncate(100);
        if (strain.length>0) {
            titleText += ":"+strain
        }
        if (culture_growth.length>0 && culture_growth!='Not specified') {
            titleText += " <span class='assay_item_sup_info'>("+culture_growth+")</span>";
        }
        titleText +=  '</span>';
        organism_text += '<li>' + titleText +
          '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">' +
          '[<a href=\"\" onclick=\"javascript:removeOrganism('+i+'); return(false);\">remove</a>]</small></li>';
    }

    organism_text += '</ul>';

    // update the page
    if(organisms.length == 0) {
        $('organism_to_list').innerHTML = '<span class="none_text">No organisms</span>';
    }
    else {
        $('organism_to_list').innerHTML = organism_text;
    }

    clearList('assay_organism_ids');

    select=$('assay_organism_ids')
    for (i=0;i<organisms.length;i++) {
        organism=organisms[i];
        id=organism[1];
        strain=organism[2]
        culture_growth=organism[3]
        o=document.createElement('option');
        o.value=id;
        o.text=id;
        o.selected=true;
        o.value=id + "," + strain + "," + culture_growth;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}

function check_show_add_publication() {
    i = $('possible_publications').selectedIndex;
    selected_id = $('possible_publications').options[i].value;
    if (selected_id == '0') {
        $('add_publication_link').hide();
    }
    else {
        $('add_publication_link').show();
    }
}

function addSelectedPublication() {
    selected_option_index = $("possible_publications").selectedIndex;
    selected_option = $("possible_publications").options[selected_option_index];
    title = selected_option.text;
    id = selected_option.value;

    if (checkNotInList(id, publications_array)) {
        publications_array.push([title,id]);
        updatePublications();
    }
    else {
        alert('The following Publication had already been added:\n\n' +
                title);
    }
}

function updatePublications() {
    publication_text = '<ul class="related_asset_list">'
    for (var i = 0; i < publications_array.length; i++) {
        publication = publications_array[i];
        title = publication[0];
        id = publication[1];
        titleText = '<span title="' + title + '">' + title.truncate(100) + '</span>';
        publication_text += '<li>' + titleText +
                '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">'
                + '[<a href="" onclick="javascript:publications_array.splice(' + i + ', 1);updatePublications(); return(false);">remove</a>]</small></li>';
    }

    publication_text += '</ul>';

    // update the page
    if (publications_array.length == 0) {
        $('publication_to_list').innerHTML = '<span class="none_text">No publications</span>';
    }
    else {
        $('publication_to_list').innerHTML = publication_text;
    }

    clearList('publication_ids');

    select = $('publication_ids');
    for (i = 0; i < publications_array.length; i++) {
        id = publications_array[i][1];
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
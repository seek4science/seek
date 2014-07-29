var strain_table = null;
var specimen_table = null;
var sample_table = null;


function check_show_existing_items(organism_element_id, existing_items_element_id, url) {
    var selected_ids = $F(organism_element_id).join();
    if (selected_ids == '0') {
        if ($(existing_items_element_id + "_spinner") != null)
            Effect.Fade(existing_items_element_id + "_spinner");
        Effect.Fade(existing_items_element_id, { duration: 0.25 });
    }
    else {
        if (url != '') {
            request = new Ajax.Request(url,
                {
                    method: 'get',
                    parameters: {
                        organism_ids: selected_ids
                    },
                    onSuccess: function(transport) {
                        Effect.Appear(existing_items_element_id, { duration: 0.25 });
                    },
                    onFailure: function(transport) {
                        alert('Something went wrong, please try again...');
                    }
                });
        }
        else {
            Effect.Appear(existing_items_element_id, { duration: 0.25 });
        }
    }
}

function show_existing_specimens() {
    Effect.Appear('existing_specimens', { duration: 0.25 })
}
function hide_existing_specimens() {
    Effect.Fade('existing_specimens', { duration: 0.25 })
}

function show_existing_samples() {
    Effect.Appear('existing_samples', { duration: 0.25 })
}
function hide_existing_samples() {
    Effect.Fade('existing_samples', { duration: 0.25 })
}

function getSelectedStrains() {
    var strain_ids  = new Array();
    if (strain_table && strain_table.length != 0){
        var selected_strain_rows = fnGetSelected(strain_table);
        for (var i=0; i< selected_strain_rows.length; i++){
            var id_index = getAttributeColumn(strain_table,"Seek ID");
            strain_ids.push(strain_table.fnGetData(selected_strain_rows[i])[id_index+1]);
        }
    }
    return strain_ids.join(',');
}

function getSelectedSpecimens() {
    var specimen_ids  = new Array();
    if (specimen_table.length != 0){
        var selected_specimen_rows = fnGetSelected(specimen_table);
        for (var i=0; i< selected_specimen_rows.length; i++){
            var id_index = getAttributeColumn(specimen_table,"Seek ID");
            specimen_ids.push(specimen_table.fnGetData(selected_specimen_rows[i])[id_index+1]);
        }
    }
    return specimen_ids.join(',');
}
/*get the column number of attribute in the table*/
function getAttributeColumn( table,attribute){
var th_columns = $j('#'+table.fnSettings().sTableId+' thead tr th');
    
for (var l = 0; l < th_columns.length; l++){
         if(th_columns[l].innerHTML==attribute){
             return l;
         }
    }
}
/* Get the rows which are currently selected */
function fnGetSelected( oTableLocal )
{
	var aReturn = new Array();
	var aTrs = oTableLocal.fnGetNodes();

	for ( var i=0 ; i<aTrs.length ; i++ )
	{
		if (aTrs[i].cells[0].firstChild.checked == true)
		{
			aReturn.push( aTrs[i] );
		}
	}
	return aReturn;
}

function checkSelectOneStrain(){
    var selected_strains = getSelectedStrains().split(',');
    if (selected_strains.length > 1){
        alert('Please select only ONE strain for this new strain to base on.');
        return false;
    }else if (selected_strains.length == 1 && selected_strains[0] != "" ){
        //add selected specimen_id to the link param
        var old_link = $('new_strain_link').href;
        var new_link = old_link.split('?')[0];
        new_link = new_link.concat('?parent_id=' + selected_strains[0]);
        new_link = new_link.concat('&from_biosamples=true');
        $('new_strain_link').href = new_link;
        return true;
    }else{
        var old_link = $('new_strain_link').href;
        var new_link = old_link.split('?')[0];
        new_link = new_link.concat('?from_biosamples=true');
        $('new_strain_link').href = new_link;
        return true;
    }

}

//if more than one specimen are selected, display the notice message
//if one specimen is selected, add the param specimen_id to the link
//else send the link without any params
function checkSelectOneSpecimen(cell_culture_or_specimen){
    var selected_specimens = getSelectedSpecimens().split(',')
    if (selected_specimens.length > 1){
       alert("Please select only ONE " + cell_culture_or_specimen + " for this sample to base on, or select NO " + cell_culture_or_specimen);
       return false;
   }else if (selected_specimens.length == 1 && selected_specimens[0] != "" ){
        //add selected specimen_id to the link param
        var old_link = $('new_sample_link').href;
        var new_link = old_link.split('?')[0];
        new_link = new_link.concat('?specimen_id=' + selected_specimens[0]);
        new_link = new_link.concat('&from_biosamples=true');
        $('new_sample_link').href = new_link
        return true;
    }else{
        var old_link = $('new_sample_link').href;
        var new_link = old_link.split('?')[0];
        new_link = new_link.concat('?from_biosamples=true');
        $('new_sample_link').href = new_link
        return true;
    }
}

function strains_of_selected_organism(organism_id, strain_selection_box_id, strain_selection_box_name){
      var updated_selection_box = '<select id=\''+ strain_selection_box_id +'\' name=\''+ strain_selection_box_name +'\'>';
        updated_selection_box += "<option value='0'>Select Strain ...</option>";
        url = "/biosamples/strains_of_selected_organism"
        request = new Ajax.Request(url, {
            method: 'get',
            parameters:{
                organism_id:organism_id
            },
            onSuccess : function(transport){
                // "true" parameter to evalJSON() activates sanitization of input
                var data = transport.responseText.evalJSON(true);
                if (data.status == 200){
                    var strains = data.strains
                    for (var i=0; i< strains.length; i++){
                        updated_selection_box += '<option value=\''+ strains[i][0] + '\'>'+ strains[i][1] +'</option>';

                   }
                }
                $('strains_of_selected_organism').innerHTML = updated_selection_box;
            },
            onFailure: function(transport){
              alert('Something went wrong, please try again...');
            }
        });

    }

function scrollToElement(element_id){
    var element = $(element_id);
    window.scroll(0,findPos(element)*0.5);
}

function findPos(obj) {
	var curtop = 0;
	if (obj.offsetParent) {
		do {
			curtop += obj.offsetTop;
		} while (obj = obj.offsetParent);
	return [curtop];
	}
}


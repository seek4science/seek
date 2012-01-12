var strain_table = null;
var specimen_table = null;
var sample_table = null;


function check_show_existing_strains(organism_element_id, existing_strains_element_id, url) {
    var selected_ids = $F(organism_element_id).join();
    if (selected_ids == '0') {
        Effect.Fade(existing_strains_element_id, { duration: 0.25 });
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
                        Effect.Appear(existing_strains_element_id, { duration: 0.25 });
                    },
                    onFailure: function(transport) {
                        alert('Something went wrong, please try again...');
                    }
                });
        }
        else {
            Effect.Appear(existing_strains_element_id, { duration: 0.25 });
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

function new_strain_form(strain_id, organism_id, url) {
    if (url != '') {
        request = new Ajax.Request(url,
            {
                method: 'get',
                parameters: {
                    id: strain_id,
                    organism_id:organism_id
                },
                onSuccess: function(transport) {
                },
                onFailure: function(transport) {
                    alert('Something went wrong, please try again...');
                }
            });
    }
}

function getSelectedStrains() {
    var strain_ids  = new Array();
    if (strain_table.length != 0){
        var selected_strain_rows = fnGetSelected(strain_table);
        for (var i=0; i< selected_strain_rows.length; i++){
            strain_ids.push(strain_table.fnGetData(selected_strain_rows[i])[5]);
        }
    }
    return strain_ids;
}

function getSelectedSpecimens() {
    var specimen_ids  = new Array();
    if (specimen_table.length != 0){
        var selected_specimen_rows = fnGetSelected(specimen_table);
        for (var i=0; i< selected_specimen_rows.length; i++){
            specimen_ids.push(specimen_table.fnGetData(selected_specimen_rows[i])[5]);
        }
    }
    return specimen_ids;
}

function existing_specimens(url) {
    var strain_ids = getSelectedStrains().join();
    if (url != '') {
        request = new Ajax.Request(url,
            {
                method: 'get',
                parameters: {
                    strain_ids: strain_ids
                },
                onSuccess: function(transport) {
                    show_existing_specimens();
                    hide_existing_samples();
                },
                onFailure: function(transport) {
                    alert('Something went wrong, please try again...');
                }
            });
    }
}

function existing_samples(url){
    var selected_specimen_rows = fnGetSelected(specimen_table);
    var specimen_ids  = new Array();
    for (var i=0; i< selected_specimen_rows.length; i++){
        specimen_ids.push(specimen_table.fnGetData(selected_specimen_rows[i])[5]);
    }
    specimen_ids = specimen_ids.join();
    if (url != '') {
        request = new Ajax.Request(url,
            {
                method: 'get',
                parameters: {
                    specimen_ids: specimen_ids
                },
                onSuccess: function(transport) {
                    show_existing_samples();
                },
                onFailure: function(transport) {
                    alert('Something went wrong, please try again...');
                }
            });
    }
}
/* Get the rows which are currently selected */
function fnGetSelected( oTableLocal )
{
	var aReturn = new Array();
	var aTrs = oTableLocal.fnGetNodes();

	for ( var i=0 ; i<aTrs.length ; i++ )
	{
		if ( $j(aTrs[i]).hasClass('row_selected') )
		{
			aReturn.push( aTrs[i] );
		}
	}
	return aReturn;
}

function checkSelectOneStrain(){
   if (getSelectedStrains().length > 1){
       alert('Please select only ONE strain for this new strain to base on.');
       return false;
   }else
        return true;
}

function checkSelectOneSpecimen(){
   if (getSelectedSpecimens().length > 1){
       alert('Please select only ONE specimen for this sample to base on, or select NO specimen');
       return false;
   }else
        return true;
}
function fadeRow(id) {
    try {
        var genotype_row_id = 'genotype_row_'.concat(id.toString())
        Effect.Fade(genotype_row_id, { duration: 0.25 });
        var gene_element_id = "genotypes_".concat(id.toString()).concat("_gene_title")
        $(gene_element_id).remove()
        var modification_element_id = "genotypes_".concat(id.toString()).concat("_modification_title")
        $(modification_element_id).remove()
        var delete_image_id = 'delete_'.concat(id.toString())
        $(delete_image_id).remove()
    } catch(e) {
        alert(e);
    }
}

function addRow(tableID) {
    var table = document.getElementById(tableID);
    var rowCount = table.rows.length;
    var row = table.insertRow(rowCount);
    row.id = 'genotype_row_'.concat(rowCount)

    var cell1 = row.insertCell(0);
    var element1 = document.createElement("input");
    element1.type = "text";
    element1.size = 10;
    element1.name = "genotypes[".concat(rowCount.toString()).concat("][gene][title]")
    element1.id = "genotypes_".concat(rowCount.toString()).concat("_gene_title")
    cell1.appendChild(element1);

    var cell2 = row.insertCell(1);
    var element2 = document.createElement("input");
    element2.type = "text";
    element2.size = 10;
    element2.name = "genotypes[".concat(rowCount.toString()).concat("][modification][title]")
    element2.id = "genotypes_".concat(rowCount.toString()).concat("_modification_title")
    cell2.appendChild(element2);

    var cell3 = row.insertCell(2);
    var element3 = document.createElement("img");
    element3.src = "/images/famfamfam_silk/cross.png";
    element3.alt = "Delete"
    element3.id = "delete_".concat(rowCount.toString())
    element3.title = "Delete this entry"
    cell3.appendChild(element3);
    cell3.children[0].onclick = function() {
        fadeRow(rowCount)
    }
}

function fadeCreateStrain() {
    Effect.Fade('strain_form', { duration: 0.25 });
    Effect.Fade('existing_strains', { duration: 0.25 });
}

function check_show_create_new_strain(element_id) {
    var selected_id = $F('strain_organism_id');
    if (selected_id == '0') {
        Effect.Fade(element_id, { duration: 0.25 });
    } else {
        Effect.Appear(element_id, { duration: 0.25 });
    }
}

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

function check_show_existing_strain(strain_id, organism_id, url) {
    if (strain_id != '' && url != '') {
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

function getSelectedStrain() {
    var elArray = document.getElementsByName('selected_strain');
    var selectedElement;
    for (var i = 0; i < elArray.length; i++) {
        if (elArray[i].checked == true) {
            selectedElement = elArray[i];
        }
    }
    if (selectedElement != null)
        return selectedElement.value
}

function getSelectedSample() {
    var elArray = document.getElementsByName('selected_sample');
    var selectedElement;
    for (var i = 0; i < elArray.length; i++) {
        if (elArray[i].checked == true) {
            selectedElement = elArray[i];
        }
    }
    if (selectedElement != null)
        return selectedElement.value
}

function getSelectedSpecimen() {
    var elArray = document.getElementsByName('selected_specimen');
    var selectedElement;
    for (var i = 0; i < elArray.length; i++) {
        if (elArray[i].checked == true) {
            selectedElement = elArray[i];
        }
    }
    if (selectedElement != null)
        return selectedElement.value
}
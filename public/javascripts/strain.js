function fadeGenotypeRow(id,action) {
    try {
        var genotype_row_id = 'genotype_row_'.concat(id.toString());
        var genotype_id =  'genotype_'.concat(id.toString());
        if ($(genotype_id) && action == 'edit') {
            $(genotype_id).value = 1;
        }
        //Dont remove the row coz it messes up the row id
        Effect.Fade(genotype_row_id, { duration: 0.25 });
        while ($(genotype_row_id).firstChild) {
                   $(genotype_row_id).removeChild($(genotype_row_id).firstChild);
        }
    } catch(e) {
        alert(e);
    }
}

function addGenotypeRow(tableID,parent_name,action) {
    var table = document.getElementById(tableID);
    var rowCount = table.rows.length;
    var row = table.insertRow(rowCount);
    row.id = 'genotype_row_'.concat(rowCount);
    var object_name = typeof(parent_name) == "undefined" ? "" : parent_name ;
    var cell1 = row.insertCell(0);
    var element1 = document.createElement("input");
    element1.type = "text";
    element1.size = 10;
    var new_id = new Date().getTime();
    element1.name = object_name.concat("[genotypes_attributes][").concat(new_id).concat("][gene_attributes][title]");
    //element1.name =  object_name.concat("[genotypes_attributes][][gene_attributes][title]");
    element1.id = object_name.replace("[","_").replace("]","").concat("_genotypes_attributes_").concat(new_id).concat("_gene_attributes_title");
    cell1.appendChild(element1);

    var cell2 = row.insertCell(1);
    var element2 = document.createElement("input");
    element2.type = "text";
    element2.size = 10;
    element2.name = object_name.concat("[genotypes_attributes][").concat(new_id).concat("][modification_attributes][title]");
    //element2.name = object_name.concat("[genotypes_attributes][][modification_attributes][title]");
    element2.id = object_name.replace("[","_").replace("]","").concat("_genotypes_attributes_").concat(new_id).concat("_modification_attributes_title");
    cell2.appendChild(element2);

    var cell3 = row.insertCell(2);
    var element3 = document.createElement("img");
    element3.src = "/images/famfamfam_silk/cross.png";
    element3.alt = "Delete"
    element3.id = "delete_genotype_".concat(rowCount.toString());
    element3.title = "Delete this entry"
    cell3.appendChild(element3);
    cell3.children[0].onclick = function() {
        fadeGenotypeRow(rowCount,action);
    }
}

function fadePhenotypeRow(id,action) {
    try {
        var phenotype_row_id = 'phenotype_row_'.concat(id.toString());
        var phenotype_id = 'phenotype_'.concat(id.toString());
        if ($(phenotype_id) && action == 'edit') {
            $(phenotype_id).value = 1;
        }

        //Dont remove the row coz it messes up the row id
        Effect.Fade(phenotype_row_id, { duration: 0.25 });
        while ($(phenotype_row_id).firstChild) {
            $(phenotype_row_id).removeChild($(phenotype_row_id).firstChild);
        }
    } catch(e) {
        alert(e);
    }
}

function addPhenotypeRow(tableID,parent_name,action) {
    var table = document.getElementById(tableID);
    var rowCount = table.rows.length;
    var row = table.insertRow(rowCount);
    row.id = 'phenotype_row_'.concat(rowCount);
    var object_name = typeof(parent_name) == "undefined" ? "" : parent_name ;
    var cell1 = row.insertCell(0);
    var element1 = document.createElement("input");
    element1.type = "text";
    element1.size = 25;

    var new_id = new Date().getTime();
    element1.name = object_name.concat("[phenotypes_attributes][").concat(new_id).concat("][description]") ;
    //element1.name =   object_name.concat("[phenotypes_attributes][][description]") ;
    element1.id = object_name.replace("[","_").replace("]","").concat("_phenotypes_attributes_").concat(new_id).concat("_description");
    cell1.appendChild(element1);

    var cell2 = row.insertCell(1);
    var element2 = document.createElement("img");
    element2.src = "/images/famfamfam_silk/cross.png";
    element2.alt = "Delete"
    element2.id = "delete_phenotype_".concat(rowCount.toString());
    element2.title = "Delete this entry"
    cell2 .appendChild(element2);
    cell2 .children[0].onclick = function() {
        fadePhenotypeRow(rowCount,action)
    }
}

function fadeCreateStrain() {
    Effect.Fade('strain_form', { duration: 0.25 });
    Effect.Fade('existing_strains', { duration: 0.25 });
}


function fadeGenotypeRow(id) {
    try {
        var genotype_row_id = 'genotype_row_'.concat(id.toString())
        //Dont remove the row coz it messes up the row id
        Effect.Fade(genotype_row_id, { duration: 0.25 });
        var gene_element_id = "genotypes_".concat(id.toString()).concat("_gene_title")
        $(gene_element_id).remove()
        var modification_element_id = "genotypes_".concat(id.toString()).concat("_modification_title")
        $(modification_element_id).remove()
        var delete_image_id = 'delete_genotype_'.concat(id.toString())
        $(delete_image_id).remove()
    } catch(e) {
        alert(e);
    }
}

function addGenotypeRow(tableID) {
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
    element3.src = "../images/famfamfam_silk/cross.png";
    element3.alt = "Delete"
    element3.id = "delete_genotype_".concat(rowCount.toString())
    element3.title = "Delete this entry"
    cell3.appendChild(element3);
    cell3.children[0].onclick = function() {
        fadeGenotypeRow(rowCount)
    }
}

function fadePhenotypeRow(id) {
    try {
        var phenotype_row_id = 'phenotype_row_'.concat(id.toString())
        //Dont remove the row coz it messes up the row id
        Effect.Fade(phenotype_row_id, { duration: 0.25 });
        var phenotype_element_id = "phenotypes_".concat(id.toString()).concat("_description")
        $(phenotype_element_id).remove()
        var delete_image_id = 'delete_phenotype_'.concat(id.toString())
        $(delete_image_id).remove()
    } catch(e) {
        alert(e);
    }
}

function addPhenotypeRow(tableID) {
    var table = document.getElementById(tableID);
    var rowCount = table.rows.length;
    var row = table.insertRow(rowCount);
    row.id = 'phenotype_row_'.concat(rowCount)

    var cell1 = row.insertCell(0);
    var element1 = document.createElement("input");
    element1.type = "text";
    element1.size = 25;
    element1.name = "phenotypes[".concat(rowCount.toString()).concat("][description]")
    element1.id = "phenotypes_".concat(rowCount.toString()).concat("_description")
    cell1.appendChild(element1);

    var cell2 = row.insertCell(1);
    var element2 = document.createElement("img");
    element2.src = "../images/famfamfam_silk/cross.png";
    element2.alt = "Delete"
    element2.id = "delete_phenotype_".concat(rowCount.toString())
    element2.title = "Delete this entry"
    cell2 .appendChild(element2);
    cell2 .children[0].onclick = function() {
        fadePhenotypeRow(rowCount)
    }
}

function fadeCreateStrain() {
    Effect.Fade('strain_form', { duration: 0.25 });
    Effect.Fade('existing_strains', { duration: 0.25 });
}


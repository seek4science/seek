function fadeRow(id) {
    try {
        var genotype_row_id = 'genotype_row_'.concat(id.toString())
        Effect.Fade(genotype_row_id, { duration: 0.25 });
        var gene_element_id = "strain_genotypes_".concat(id.toString()).concat("_gene_title")
        $(gene_element_id).remove()
        var modification_element_id = "strain_genotypes_".concat(id.toString()).concat("_modification_title")
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
    element1.name = "strain[genotypes][".concat(rowCount.toString()).concat("][gene][title]")
    element1.id = "strain_genotypes_".concat(rowCount.toString()).concat("_gene_title")
    cell1.appendChild(element1);

    var cell2 = row.insertCell(1);
    var element2 = document.createElement("input");
    element2.type = "text";
    element2.size = 10;
    element2.name = "strain[genotypes][".concat(rowCount.toString()).concat("][modification][title]")
    element2.id = "strain_genotypes_".concat(rowCount.toString()).concat("_modification_title")
    cell2.appendChild(element2);

    var cell3 = row.insertCell(2);
    var element3 = document.createElement("img");
    element3.src = "/images/famfamfam_silk/cross.png";
    element3.alt = "Delete"
    element3.id = "delete_".concat(rowCount.toString())
    element3.title = "Delete this entry"
    cell3.appendChild(element3);
    cell3.children[0].onclick = function(){ fadeRow(rowCount)}
}

function removeStrainForm(){
    $('strain_form').remove();
}


var organisms = new Array();

function checkOrganismNotInList(organism_id,strain_id,culture_growth,t_title){
        toAdd = true;

        for (var i = 0; i < organisms.length; i++){
            if (organisms[i][0] == title
                    && organisms[i][1] == organism_id
                    && organisms[i][3] == strain_id
                    && organisms[i][4] == culture_growth
                    && organisms[i][6] == t_title) {

                toAdd = false;
                break;
            }
        }
        if (!toAdd) {
            alert("Organism already exists!");
        }
        return toAdd;
    }

function addOrganism(title,id,strain_info,strain_id,culture_growth,t_id,t_title) {
    if(checkOrganismNotInList(id,strain_id,culture_growth,t_title)){
       organisms.push([title,id,strain_info,strain_id,culture_growth,t_id,t_title]);
       updateOrganisms();
    }
}

function addSelectedOrganism() {
    selected_option_index=$("possible_organisms").selectedIndex;
    selected_option=$("possible_organisms").options[selected_option_index];
    title=selected_option.innerHTML;
    id=selected_option.value;
    //strains selection list can be null when no strains is defined to an organism
    if($('strains')){
        strain_index = $('strains').selectedIndex;
        if (strain_index!=0) {
            strain_info = $('strains')[strain_index].text;
            strain_id = $('strains')[strain_index].value;
        } else {
            strain_id="";
            strain_info="";
        }
    }
    else{
       strain_id="";
       strain_info="";
    }

    selected_option_index=$('culture_growth').selectedIndex;
    selected_option=$('culture_growth').options[selected_option_index];
    if (selected_option_index==0) {
      culture_growth="";
    }else{
        culture_growth=selected_option.text;
    }

    if($("possible_tissue_and_cell_types")){

        selected_option_index = $("possible_tissue_and_cell_types").selectedIndex;
        selected_option = $("possible_tissue_and_cell_types").options[selected_option_index];

        t_id = selected_option.value;

        if($('tissue_and_cell_type').value=="" && t_id != 0){
            t_title = selected_option.text;
            addOrganism(title,id,strain_info,strain_id,culture_growth,t_id,t_title);

        }
        if($('tissue_and_cell_type').value!="" && t_id == 0) {
            t_title = $('tissue_and_cell_type').value;
            addOrganism(title,id,strain_info,strain_id,culture_growth,0,t_title);
        }

        if(t_id == 0 && $('tissue_and_cell_type').value=="") {
            t_title = "";
            addOrganism(title,id,strain_info,strain_id,culture_growth,t_id,t_title);
        }
    }
    else{
      addOrganism(title,id,strain_info,strain_id,culture_growth, 0, "");
    }

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
        strain_info=organism[2];
        strain_id=organism[3];
        culture_growth=organism[4];
        tissue_and_cell_type_id=organism[5];
        tissue_and_cell_type_title = organism[6];
        titleText = '<span title="' + title + '">' +  title.truncate(100) + '</span>';

        if (strain_info.length>0) {
            titleText += ":"+ "<span> " + strain_info + "</span>";
        }
        if (tissue_and_cell_type_title.length>0) {
            titleText += ":"+ tissue_and_cell_type_title+ "</span>";
        }
        if (culture_growth.length>0 && culture_growth!='Not specified') {
            titleText += " <span>("+culture_growth+")</span>";
        }
        titleText +=  '</span>';
        organism_text += '<li>' + titleText +
          '&nbsp;&nbsp;<small style="vertical-align: middle;">' +
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

    select=$('assay_organism_ids');
    for (i=0;i<organisms.length;i++) {
        organism=organisms[i];
        id=organism[1];
        strain_info=organism[2];
        strain_id=organism[3];
        culture_growth=organism[4];
        tissue_and_cell_type_id=organism[5];
        tissue_and_cell_type_title = organism[6];
        o=document.createElement('option');
        o.value=id;
        o.text=id;
        o.selected=true;
        o.value=id + "," + strain_info + "," + strain_id  + "," + culture_growth+ "," + tissue_and_cell_type_id  + "," + tissue_and_cell_type_title;
        try {
            select.add(o); //for older IE version
        }
        catch (ex) {
            select.add(o,null);
        }
    }
}
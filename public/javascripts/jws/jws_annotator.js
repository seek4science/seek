var annotations = new Array();
  var cached_annotations = new Array();
  var search_results = new Array();

  function create_annotator_panel_cookies() {
    create_panel_cookies_by_id('species_panel');
    create_panel_cookies_by_id('reactions_panel');
    create_panel_cookies_by_id('attribution_annotations_panel');
  }

  function read_annotator_panel_cookies() {
    read_panel_cookies_from_id('species_panel');
    read_panel_cookies_from_id('reactions_panel');
    read_panel_cookies_from_id('attribution_annotations_panel');
  }

  function submit_annotations() {
      update_annotation_field("annotationsSpecies","species",annotations);
      update_annotation_field("annotationsReactions","reactions",annotations);
      update_authors_field();
      $('submit_annotations_button').disabled=true;
      $('submit_annotations_button').value = "Submitting ...";
      $('form').submit();
  }

  var n_authors = 0;
  function new_author() {
      add_author("","","","");
  }

  function remove_author(element_id) {
      el=$(element_id);
      if (confirm("Are you sure you wish to remove this Author?")) {
        el.remove();
        n_authors -= 1;
      }

  }

  function add_author(first_name,last_name,email,institution) {
      n_authors += 1;
      panel=$('authors_panel');
      el = document.createElement("div");
      el.id="author_"+n_authors;
      html="<h2>Author</h2><br/>";
      html+="First name: <input name='firstName' id='first_name_"+n_authors+"' type='text' value='"+decodeURI(first_name)+"'/>"
      html+="Last name: <input name='last_name' id='last_name_"+n_authors+"' type='text' value='"+decodeURI(last_name)+"'/><br/>"
      html+="Email: <input name='email' id='email_"+n_authors+"' type='text' value='"+decodeURI(email)+"'/>"
      html+="Institution: <input name='institution' id='institution_"+n_authors+"' type='text' value='"+decodeURI(institution)+"'/><br/>"
      html+="<a href=\"javascript:remove_author('"+el.id+"');\">Remove author</a>";
      el.innerHTML=html;
      panel.appendChild(el);
  }

  function update_authors_field() {
      authors=$('authors');
      authors.value="";
      author_panel = $('authors_panel');
      author_elements = author_panel.getElementsByTagName("div");
      for (var i=0;i<author_elements.length;i++) {
          author_element=author_elements[i];
          inputs=author_element.getElementsByTagName("input");
          str=inputs[0].value+","+inputs[1].value+","+inputs[2].value+","+inputs[3].value+"\n";
          authors.value=authors.value+str;
      }
  }

  function submit_search(prefix) {
      $('form').following_action.value = "annotate";

      if (prefix == "species") {
          $('reactions_search_box').value="";
          $('reactions_selected_symbol').value="";
          $('nameToSearch').value=$('species_search_box').value;
      }

      if (prefix == "reactions") {
          $('species_search_box').value="";
          $('species_selected_symbol').value="";
          $('nameToSearch').value=$('reactions_search_box').value;
      }
      button=$(prefix+"_search_button");
      button.disabled = true;
      button.value = "Searching ...";
      create_annotator_panel_cookies();
      submit_annotations();
  }

  function draw_cached_annotation_table(prefix,key,triplets) {
      parent_element = $(prefix+"_cached_annotations");
      table_id=encodeURI(key)+"_table";
      table = "<table id='"+table_id+"' style='display:none;' class='annotation_table'>";
      for (var i=0;i<triplets.length;i++) {
          trip = triplets[i];
              row = "<tr><td>"+trip.urn+"</td><td>" + trip.full_name +"</td>";
              js="javascript:add_cached_annotation('"+prefix+"','"+key+"',"+i+");";

              row = row + "<td><a href=\""+js+"\">Add</a></td></tr>";
              table=table+row;
      }
      parent_element.innerHTML=parent_element.innerHTML+table;
  }

  function draw_assigned_annotation_table(prefix,key) {
      if (annotations[prefix]!=undefined && annotations[prefix][key] != undefined) {
          triplets = annotations[prefix][key];
          table="<table class='annotation_table'>";
          for (var i=0;i<triplets.length;i++) {
              trip = triplets[i];
              row = "<tr><td>"+trip.urn+"</td><td>" + trip.full_name +"</td>";
              js="javascript:drop_annotation('"+prefix+"','"+key+"',"+i+");"
              row = row + "<td><a href=\""+js+"\">Drop</a></td></tr>";
              table=table+row;
          }
          table=table+"</table>";
          $(prefix+"_assigned_annotations").innerHTML = table;
      }
  }

  function drop_annotation(prefix,key,index) {
      if (annotations[prefix]!=undefined && annotations[prefix][key] != undefined) {
        annotations[prefix][key].splice(index,1);
        draw_assigned_annotation_table(prefix,key);
      }
  }

  function store_annotations(prefix,key,triplets) {
      if (annotations[prefix] == undefined) {
          annotations[prefix] = new Array();
      }
      annotations[prefix][key] = triplets;
  }

  function store_cached_annotations(prefix,key,triplets) {
      if (cached_annotations[prefix] == undefined) {
          cached_annotations[prefix] = new Array();
      }
      cached_annotations[prefix][key] = triplets;
  }

  function store_search_results(triplets) {
      search_results = triplets;
  }

  function display_cached_annotation_table(prefix,key) {
      hide_all_cached_annotation_tables(prefix);
      table_id=encodeURI(key)+"_table";
      el=$(table_id);
      if (el != undefined) {
        el.style.display="block";
      }
  }

  function hide_all_cached_annotation_tables(prefix) {
      for (var k in cached_annotations[prefix]) {
          table_id=encodeURI(k)+"_table";
          el=$(table_id);
          if (el != undefined) {
            el.style.display="none";
          }
      }
  }

  function add_search_result(prefix,key,index) {
      if (annotations[prefix] == undefined) {
          annotations[prefix]=new Array();
      }
      if (annotations[prefix][key] == undefined) {
          annotations[prefix][key] = new Array();
      }
      triplet = search_results[index];
      annotations[prefix][key].push(triplet);
      draw_assigned_annotation_table(prefix,key);
  }

  function add_cached_annotation(prefix,key,index) {
      if (annotations[prefix] == undefined) {
          annotations[prefix]=new Array();
      }
      if (annotations[prefix][key] == undefined) {
          annotations[prefix][key] = new Array();
      }
      triplet = cached_annotations[prefix][key][index];
      annotations[prefix][key].push(triplet);
      draw_assigned_annotation_table(prefix,key);
  }

  function display_search_results(prefix,key,search_term,triplets) {
      annotation_selected(prefix,key);
      hide_all_cached_annotation_tables(prefix);
      parent_element = $(prefix+"_search_results");
      table_id=encodeURI(key)+"_table";
      table = "<table class='annotation_table'>";
      for (var i=0;i<triplets.length;i++) {
          trip = triplets[i];
              row = "<tr><td>"+trip.urn+"</td><td>" + trip.full_name +"</td>";
              js="javascript:add_search_result('"+prefix+"','"+key+"',"+i+");";

              row = row + "<td><a href=\""+js+"\">Add</a></td></tr>";
              table=table+row;
      }
      $(prefix+"_search_box").value=search_term;
      parent_element.innerHTML=table;
      parent_element.style.display = "block";
  }

  function hide_search_results(prefix) {
      parent_element = $(prefix+"_search_results");
      parent_element.style.display="none";

  }

  function annotation_selected(prefix,key) {
    draw_assigned_annotation_table(prefix,key);
    hide_search_results(prefix);
    display_cached_annotation_table(prefix,key);
    $(prefix+'_selected_annotation').innerHTML = key;
    $(prefix+'_search_box').value = key;
    $(prefix+'_selected_symbol').value = key;
  }



  function update_annotation_field(element_id,prefix,annotations) {
      text="";
      for (var key in annotations[prefix]) {
          triplets=annotations[prefix][key];
          for (var i=0;i<triplets.length;i++) {
              if (triplets[i]!=undefined) {
                text=text+key+" "+triplets[i].urn+" "+triplets[i].full_name+"\n"
              }
          }
      }
      $(element_id).value=text;
  }
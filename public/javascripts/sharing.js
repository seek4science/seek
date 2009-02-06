// SysMO: sharing.js
// based on osp.js from myExperiment


// global declarations
PRIVATE = null;
EVERYONE = null;
ALL_REGISTERED_USERS = null;
ALL_SYSMO_USERS = null;
CUSTOM_PERMISSIONS_ONLY = null;
// --
DETERMINED_BY_GROUP = null;
NO_ACCESS = null;
VIEWING = null;
DOWNLOADING = null;
EDITING = null;

GET_POLICY_DEFAULTS_LINK = null;
GET_INSTITUTIONS_LINK = null;
GET_ALL_INSTITUTIONS_LINK = null;

var policy_settings = new Object();
var permissions_for_set = {};
var permission_settings = new Array();

var receivedPolicySettings = null;
var receivedProjectInstitutions = null;


function init_sharing() {
  PRIVATE = parseInt($('const_private').value);
	EVERYONE = parseInt($('const_everyone').value);
	ALL_REGISTERED_USERS = parseInt($('const_all_registered_users').value);
	ALL_SYSMO_USERS = parseInt($('const_all_sysmo_users').value);
	CUSTOM_PERMISSIONS_ONLY = parseInt($('const_custom_permissions_only').value);
	
	DETERMINED_BY_GROUP = parseInt($('const_determined_by_group').value);
	NO_ACCESS = parseInt($('const_no_access').value);
	VIEWING = parseInt($('const_viewing').value);
	DOWNLOADING = parseInt($('const_downloading').value);
	EDITING = parseInt($('const_editing').value);
}
	

function setSharingElementVisibility(sharing_scope)
{
	switch(sharing_scope)
	{
		case PRIVATE:
		  $('include_custom_sharing_div_' + EVERYONE).hide();
			$('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
			$('include_custom_sharing_div_' + ALL_SYSMO_USERS).hide();
			$('cb_use_whitelist').disabled = true;
			$('cb_use_blacklist').disabled = true;
		  setCustomSharingDivVisibility(PRIVATE);
		  break;
		case EVERYONE:
		  $('include_custom_sharing_div_' + EVERYONE).show();
			$('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
			$('include_custom_sharing_div_' + ALL_SYSMO_USERS).hide();
			$('cb_use_whitelist').disabled = false;
			$('cb_use_blacklist').disabled = false;
			setCustomSharingDivVisibility(EVERYONE);
		  break;
		case ALL_REGISTERED_USERS:
		  $('include_custom_sharing_div_' + EVERYONE).hide();
			$('include_custom_sharing_div_' + ALL_REGISTERED_USERS).show();
			$('include_custom_sharing_div_' + ALL_SYSMO_USERS).hide();
			$('cb_use_whitelist').disabled = false;
			$('cb_use_blacklist').disabled = false;
			setCustomSharingDivVisibility(ALL_REGISTERED_USERS);
		  break;
		case ALL_SYSMO_USERS:
			$('include_custom_sharing_div_' + EVERYONE).hide();
			$('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
			$('include_custom_sharing_div_' + ALL_SYSMO_USERS).show();
			$('cb_use_whitelist').disabled = false;
			$('cb_use_blacklist').disabled = false;
			setCustomSharingDivVisibility(ALL_SYSMO_USERS);
		  break;
		case CUSTOM_PERMISSIONS_ONLY:
		  $('include_custom_sharing_div_' + EVERYONE).hide();
			$('include_custom_sharing_div_' + ALL_REGISTERED_USERS).hide();
			$('include_custom_sharing_div_' + ALL_SYSMO_USERS).hide();
			$('cb_use_whitelist').disabled = false;
			$('cb_use_blacklist').disabled = false;
			setCustomSharingDivVisibility(CUSTOM_PERMISSIONS_ONLY);
		  break;
		default:
		  
	}
}


function setCustomSharingDivVisibility(sharing_scope)
{
	if ((sharing_scope >= ALL_SYSMO_USERS && sharing_scope <= EVERYONE && $('include_custom_sharing_'+sharing_scope).checked)
	    || sharing_scope == CUSTOM_PERMISSIONS_ONLY)
	{
		$('specific_sharing').show();
	}
	else
	{
		$('specific_sharing').hide();
	}
}


function loadDefaultProjectPolicy(project_id) {
  $('policy_loading_spinner').style.display = "inline";
  
  request = new Ajax.Request(GET_POLICY_DEFAULTS_LINK, 
                             { method: 'get',
                               parameters: {policy_type: 'default', entity_type: 'Project', entity_id: project_id},
                               onSuccess: function(transport){       
                                 $('policy_loading_spinner').style.display = "none";
                                 
                                 // "true" parameter to evalJSON() activates sanitization of input
                                 var data = transport.responseText.evalJSON(true);
                                 
                                 if (data.status == 200) {
                                   msg = data.found_exact_match ? 'Default policy found and loaded' : 'Couldn\'t find default policy for this Project,\nsystem defaults loaded instead.'
                                   alert(msg);
                                   
                                   receivedPolicySettings = data;
                                   
                                   parsePolicyJSONData(data);
                                   updateSharingSettings();
                                 }
                                 else {
                                   error_status = data.status;
                                   error_message = data.error
                                   alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
                                 }
                               },
                               onFailure: function(transport){
                                 $('policy_loading_spinner').style.display = "none";
                                 alert('Something went wrong, please try again...'); 
                               }    
                             });

}


function parsePolicyJSONData(data) {
  // re-initialize data structures in case this is run more than one time
  policy_settings = new Object();
  permissions_for_set = {};
  permission_settings = new Array();
  
  policy_settings = data.policy
  
  for(var i = 0; i < data.permission_count; i++)
  {
    // permission IDs are present - if required
    // example: perm_id = data.permissions[i][0];
    
    // process all permissions and categorize by contributor types
    perm_settings = data.permissions[i][1];

    switch(perm_settings.contributor_type) {
      case "FavouriteGroup":
        // the only thing to check here is that the current FavouriteGroup is a whitelist/blacklist
        // (skip this group if it is; process identically to other contributor types otherwise)
        if(perm_settings.whitelist_or_blacklist)
          continue;
          
      case "Person":
      case "WorkGroup":
      case "Project":
      case "Institution":
        addContributor(perm_settings.contributor_type, perm_settings.contributor_name, perm_settings.contributor_id, perm_settings.access_type);
        break;
      default:
        // do nothing for unknown permission types
    }
  }
}


function updateSharingSettings() {
  // ************** STANDARD SETTINGS ***************
  // reset previous settings
  $('include_custom_sharing_' + EVERYONE).checked = false;
  $('include_custom_sharing_' + ALL_REGISTERED_USERS).checked = false;
  $('include_custom_sharing_' + ALL_SYSMO_USERS).checked = false;
  
  $('access_type_select_' + EVERYONE).selectedIndex = 0;
  $('access_type_select_' + ALL_REGISTERED_USERS).selectedIndex = 0;
  $('access_type_select_' + ALL_SYSMO_USERS).selectedIndex = 0;
  
  
  // set all main policy settings..
  // ..sharing scope
  $('sharing_scope_' + policy_settings.sharing_scope).checked = true;
  
  // ..access_type and usage of custom permissions
  if(policy_settings.sharing_scope >= ALL_SYSMO_USERS && policy_settings.sharing_scope <= EVERYONE) {
    access_type_select = $('access_type_select_' + policy_settings.sharing_scope)
    for(var i = 0; i < access_type_select.options.length; i++)
      if(access_type_select.options[i].value == policy_settings.access_type) {
        access_type_select.selectedIndex = i;
        break;
      }
    
    if(policy_settings.use_custom_sharing)
      $('include_custom_sharing_' + policy_settings.sharing_scope).checked = true;  
  }
  
  // ..whitelist / blacklist settings
  $('cb_use_whitelist').checked = policy_settings.use_whitelist;
  $('cb_use_blacklist').checked = policy_settings.use_blacklist;
  
  
  // make sure that correct DIVs on the page are visible (same mechanism as if the
  // selections were made on the page, rather than from JavaScript)
  setSharingElementVisibility(policy_settings.sharing_scope);
  
  
  // ************** CUSTOM PERMISSIONS ***************
  // build custom permissions list and set relevant other options
  updateCustomSharingSettings();
}


function updateCustomSharingSettings() {
  // iterate through all categories of contributors in existing permissions
  // and build the "shared with" list
  
  var shared_with = '';
  
  for(contributor_type in permissions_for_set)
    for(var i = 0; i < permission_settings[contributor_type].length; i++) {
      shared_with += '<b>' + contributor_type + '</b>: ' + permission_settings[contributor_type][i][0]
                           + '&nbsp;&nbsp;<span style="color: #5F5F5F;">('+ accessTypeTranslation(permission_settings[contributor_type][i][2]) +')</span>' 
                           + '&nbsp;&nbsp;&nbsp;<small style="vertical-align: middle;">' 
                           + '[<a href="" onclick="javascript:deleteContributor(\''+ contributor_type +'\', '+ i +'); return(false);">delete</a>]</small><br/>';
    }
    
  // remove the last line break
  if(shared_with.length > 0) {
    shared_with = shared_with.slice(0,-5);
  }
  
  
  // update the page
  if(shared_with.length == 0) {
    $('shared_with_list').innerHTML = '<span class="none_text">No one</span>';
  }
  else {
    $('shared_with_list').innerHTML = shared_with;
  }
}


function accessTypeTranslation(access_type) {
  txt = '';
  
  switch(access_type) {
    case DETERMINED_BY_GROUP:
      txt = 'individual access rights for each member';
      break;
    case NO_ACCESS:
      txt = 'no access';
      break;
    case VIEWING:
      txt = 'viewing only';
      break;
    case DOWNLOADING:
      txt = 'viewing and downloading only';
      break;
    case EDITING:
      txt = 'viewing, downloading and editing';
      break;
  }
  
  return(txt);
}


// removes a contributor from "shared with" list and updates the displayed list
function deleteContributor(contributor_type, contributor_id) {
  // update the index list (decrement count of the elements of 'contributor_type' type);
  // (the key can stay there, even if the count goes down to zero)
  permissions_for_set[contributor_type]--;
  
  // remove the actual record for the contributor
  permission_settings[contributor_type].splice(contributor_id, 1);
  
  // update the page
  updateCustomSharingSettings();
}


// adds a contributor to "shared with" list and updates the displayed list
function addContributor(contributor_type, contributor_name, contributor_id, access_type) {
  new_entry = true;
  
  // check if such (legal!) type of contributor was encoutered before --
  // if so, increment the number of occurrences of this type;
  // if not, add to set of contributor types and initialise array
  if(contributor_type in permissions_for_set)
    // such type has been seen before - check if this contributor isn't in the list yet
    if(checkContributorNotInList(contributor_type, contributor_id))
      permissions_for_set[contributor_type]++;
    else
      new_entry = false;
  else {
    permissions_for_set[contributor_type] = 0;
    permission_settings[contributor_type] = new Array();
  }
  
  
  if(new_entry) {
	  // add current values into the associative array of permissions:
	  // first index is the category of contributor type of the permission, the second - consecutive
	  // number of occurrences of permissions for such type of contributor
	  permission_settings[contributor_type][permissions_for_set[contributor_type]] = 
	    [contributor_name, contributor_id, access_type];
	  
	  // update visible page
	  updateCustomSharingSettings();
	}
	else {
	  alert('Already in the list!');
	}
}


function checkContributorNotInList(contributor_type, contributor_id) {
  rtn = true;
  
  for(var i = 0; i < permission_settings[contributor_type].length; i++)
    if(permission_settings[contributor_type][i][1] == contributor_id) {
      rtn = false;
      break;
    }
  
  return(rtn);
}

// ***************  Project & Institution Selection  *****************

function updateProjectInstitutionVisibility(step_idx) {
  switch(step_idx) {
    case 1:
      $('proj_select_step_1').className = "note_text";
      $('proj_select_step_2').className = "note_text_disabled";
      $('proj_select_step_3').className = "note_text_disabled";
      
      $('proj_select_step_div_1').show();
      $('proj_select_step_div_2').hide();
      $('proj_select_step_div_3').hide();
      
      $('proj_select_prev_link').hide();
      $('proj_select_next_link').show();
      $('proj_select_add_link').hide();
      break;
      
    case 2:
      $('proj_select_step_1').className = "note_text_disabled";
      $('proj_select_step_2').className = "note_text";
      $('proj_select_step_3').className = "note_text_disabled";
      
      $('proj_select_step_div_1').hide();
      $('proj_select_step_div_2').show();
      $('proj_select_step_div_3').hide();
      
      $('proj_select_prev_link').show();
      $('proj_select_next_link').show();
      $('proj_select_add_link').hide();
      break;
    
    case 3:
      $('proj_select_step_1').className = "note_text_disabled";
      $('proj_select_step_2').className = "note_text_disabled";
      $('proj_select_step_3').className = "note_text";
      
      $('proj_select_step_div_1').hide();
      $('proj_select_step_div_2').hide();
      $('proj_select_step_div_3').show();
      
      $('proj_select_prev_link').show();
      $('proj_select_next_link').hide();
      $('proj_select_add_link').show();
      break;
  }
}


function projectInstitutionStepAction(step_increment) {
  // check if not moving before Step 1 and past Step 3
  new_step_idx = parseInt($('proj_select_step_index').value) + step_increment
  
  if(new_step_idx >= 1 && new_step_idx <= 3) {
    $('proj_select_step_index').value = new_step_idx
    
    switch(new_step_idx) {
      case 1:
        updateProjectInstitutionVisibility(new_step_idx);
        break;
        
      case 2:
        if(step_increment > 0) {
          selected_option = $('proj_project_select').options[$('proj_project_select').selectedIndex];
          loadInstitutionsForProject(selected_option.value, selected_option.text);
        }
        else {
          updateProjectInstitutionVisibility(new_step_idx);
        }
        break;
        
      case 3:
        updateProjectInstitutionVisibility(new_step_idx);
        break;
    }
  }
  
}


function loadInstitutionsForProject(project_id, project_name) {
  $('institutions_loading_spinner').style.display = "inline";
  
  // choose a URL to get values from - if project wasn't selected, return all institutions
  request_url = (project_id == "") ? GET_ALL_INSTITUTIONS_LINK : GET_INSTITUTIONS_LINK;
  
  request = new Ajax.Request(request_url, 
                             { method: 'get',
                               parameters: {id: project_id},
                               onSuccess: function(transport){       
                                 $('institutions_loading_spinner').style.display = "none";
                                 
                                 // "true" parameter to evalJSON() activates sanitization of input
                                 var data = transport.responseText.evalJSON(true);
                                 
                                 if (data.status == 200) {
                                   receivedProjectInstitutions = data;
                                   
                                   // clear any previous contents
                                   $('proj_institution_select').options.length = 0;
                                   next_index_to_use = 0;
                                   
                                   // if a particular project has been selected, add an option "all project"
                                   if(project_id != "") {
                                     $('proj_institution_select').options[0] = new Option("All "+ project_name +" Project", "");
                                     next_index_to_use++;
                                     prefix_txt = project_name + " @ ";
                                   }
                                   else {
                                     prefix_txt = '';
                                   }
                                   
                                   // fill with new contents
                                   for(var i = 0; i < data.institution_list.length; i++) {
                                     $('proj_institution_select').options[next_index_to_use] = new Option(prefix_txt + data.institution_list[i][0], data.institution_list[i][1]);
                                     next_index_to_use++;
                                   }
                                   
                                   
                                   // show relevant bits of the page
                                   updateProjectInstitutionVisibility(2);
                                 }
                                 else {
                                   error_status = data.status;
                                   error_message = data.error
                                   alert('An error occurred...\n\nHTTP Status: ' + error_status + '\n' + error_message);
                                 }
                               },
                               onFailure: function(transport){
                                 $('institutions_loading_spinner').style.display = "none";
                                 alert('Something went wrong, please try again...');
                               }    
                             });

}


function addProjectInstitution() {
  project_id = $('proj_project_select').options[$('proj_project_select').selectedIndex].value;
  institution_id = $('proj_institution_select').options[$('proj_institution_select').selectedIndex].value;
  access_type = parseInt($('proj_access_type_select').options[$('proj_access_type_select').selectedIndex].value);
  
  if(project_id == "") {
    add_type = "Institution";
    add_id = parseInt(institution_id);
    
    for(var i = 0; i < receivedProjectInstitutions.institution_list.length; i++)
      if(receivedProjectInstitutions.institution_list[i][1] == institution_id)
        add_name = receivedProjectInstitutions.institution_list[i][0];
  }
  else if(institution_id == "") {
    add_type = "Project";
    add_id = parseInt(project_id);
    add_name = $('proj_project_select').options[$('proj_project_select').selectedIndex].text;
  }
  else {
    institution_id = parseInt(institution_id);
    
    add_type = "WorkGroup";
    add_name = $('proj_institution_select').options[$('proj_institution_select').selectedIndex].text;
    
    for(var i = 0; i < receivedProjectInstitutions.institution_list.length; i++)
      if(receivedProjectInstitutions.institution_list[i][1] == institution_id)
        add_id = receivedProjectInstitutions.institution_list[i][2];
  }
  
  // add to list and update..
  addContributor(add_type, add_name, add_id, access_type);
  // ..and reset this section to run from new
  $('proj_select_step_index').value = 1;
  updateProjectInstitutionVisibility(1);
}



// ********************************************************

function trimSpaces(str) {

  while ((str.length > 0) && (str.charAt(0) == ' '))
    str = str.substring(1);

  while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
    str = str.substring(0, str.length - 1);

  return str;
}

// tags

var tags = new Array();

function updateTagList() {

  var markup = '';

  if (tags.length == 0) {

    markup = '<i>None</i>';

  } else {

    for (var i = 0; i < tags.length; i++)
      markup += tags[i] +
        '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteTag(\'' + tags[i].replace("'", "\\'") +
        '\'); return false;">delete</a>]</small><br />';
  }

  document.getElementById('tags_current_list').innerHTML = markup;

  // also update the web form

  var tag_list = '';

  for (var i = 0; i < tags.length; i++) {
    tag_list += tags[i];

    if (i != (tags.length - 1))
      tag_list += ',';
  }

  document.getElementById('tag_list').value = tag_list;
}

function addTag(str) {

  var newTags = str.split(',');
  
  for (var i = 0; i < newTags.length; i++) {

    var tag = trimSpaces(newTags[i]);

    tag = tag.replace('"', '');

    if (tag.length == 0)
      continue;

    if (tags.indexOf(tag) != -1)
      continue;

    tags.push(tag);
  }

  updateTagList();
}

function deleteTag(tag) {

  var i = tags.indexOf(tag);

  if (i == -1)
    return;

  tags.splice(i, 1);
  updateTagList();
}

// end tags

function toggle_visibility(id) {
   var e = document.getElementById(id);
   if(e.style.display == 'block')
      e.style.display = 'none';
   else
      e.style.display = 'block';
}

// credit and attribution

var credit_me = true;
var credit_users = new Object();
var credit_groups = new Object();

function updateAuthorList() {
	
	var markup = '';
	
	if (credit_me)
	{
		markup += 'Me&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAuthor(\'me\', null); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in credit_users)
	{
		markup += 'User: ' + credit_users[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAuthor(\'user\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in credit_groups)
	{
		markup += 'Group: ' + credit_groups[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAuthor(\'group\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	if (markup == '')
	{
		markup = '<i>None</i>';
	}
	
	document.getElementById('authors_list').innerHTML = markup;
	
	// Also update web form (the hidden input fields)
	
	// Me
	if (credit_me)
	{
		document.getElementById('credits_me').value = "true";
	}
	else 
	{
		document.getElementById('credits_me').value = "false";
	}
	
	// Users (friends + other users)
	var users_list = '';
	
	for (var key in credit_users)
	{
		users_list += key + ',';
	}
	
	document.getElementById('credits_users').value = users_list;
	
	// Groups
	var groups_list = '';
	
	for (var key in credit_groups)
	{
		groups_list += key + ',';
	} 
	
	document.getElementById('credits_groups').value = groups_list;
}

function addAuthor() {
    
	// Me
    if (document.getElementById('author_option_1').checked)
	{
		credit_me = true;
	}
	// One of my Friends 
	else if (document.getElementById('author_option_2').checked)
	{
		var x = document.getElementById('author_friends_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_users[y.value] = y.text;
		}
	}
	// A user on myExperiment who is not a Friend.
	else if (document.getElementById('author_option_3').checked)
	{
		var x = document.getElementById('author_otheruser_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_users[y.value] = y.text;
		}
	}
	// A myExperiment Group
	else if (document.getElementById('author_option_4').checked)
	{
		var x = document.getElementById('author_networks_dropdown');
		
		if (x.options.length > 0)
		{
			var y = x.options[x.selectedIndex];
	     	credit_groups[y.value] = y.text;
		}
	}
	
	updateAuthorList();
}

function deleteAuthor(type, key) {

	if (type == 'me')
	{
		credit_me = false;
	}
	else if (type == 'user')
	{
		delete credit_users[key];
	}
	else if (type == 'group')
	{
		delete credit_groups[key];
	}
	
	updateAuthorList();
}

function update_author(parentId) {

    if (parentId == 'author_option_2')
    {
        document.getElementById('author_friends_box').style.display = 'block';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_3')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'block';
        document.getElementById('author_networks_box').style.display = 'none';
    }
    else if (parentId == 'author_option_4')
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'block';
    }
    else
    {
        document.getElementById('author_friends_box').style.display = 'none';
        document.getElementById('author_otheruser_box').style.display = 'none';
        document.getElementById('author_networks_box').style.display = 'none';
    }
}

var attributions_workflows = new Object();
var attributions_files = new Object();

function updateAttributionsList() {
	
	var markup = '';
	
	for (var key in attributions_workflows)
	{
		markup += 'Workflow: ' + attributions_workflows[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAttribution(\'workflow\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	for (var key in attributions_files)
	{
		markup += 'File: ' + attributions_files[key] + '&nbsp;&nbsp;&nbsp;<small>[<a href="" onclick="javascript:deleteAttribution(\'file\', ' + key + '); ' +
    		'return false;">delete</a>]</small><br/>';
	}
	
	if (markup == '')
	{
		markup = '<i>None</i>';
	}
	
	document.getElementById('attribution_list').innerHTML = markup;
	
	// Also update web form (the hidden input fields)
	
	var attr_workflows_list = '';
	
	for (var key in attributions_workflows)
	{
		attr_workflows_list += key + ',';
	}
	
	document.getElementById('attributions_workflows').value = attr_workflows_list;
	
	var attr_files_list = '';
	
	for (var key in attributions_files)
	{
		attr_files_list += key + ',';
	} 
	
	document.getElementById('attributions_files').value = attr_files_list;
}

function addAttribution(type) {
	
	if (type == 'existing_workflow') {
		var x = document.getElementById('existingworkflows_dropdown');
		
		if (x.options.length > 0) {
			var y = x.options[x.selectedIndex];
			attributions_workflows[y.value] = y.text;
		}
	}
	else if (type == 'existing_file') {
		var x = document.getElementById('existingfiles_dropdown');
		
		if (x.options.length > 0) {
			var y = x.options[x.selectedIndex];
			attributions_files[y.value] = y.text;
		}
	} 
	
	updateAttributionsList();
}

function deleteAttribution(type, id) {
	
	if (type == 'workflow') {
		delete attributions_workflows[id];
	}
	else if (type == 'file') {
		delete attributions_files[id];
	}
	
	updateAttributionsList();
}

// end credit and attribution

function toggle_copy_inherit(obj) {
    var f = document.getElementById('copy_inherit_sharing_box');
    
    if(obj.oldText)
    {
        f.style.display = 'none';
        obj.innerHTML = obj.oldText;
        obj.oldText = null;
    } 
    else 
    {
        f.style.display = 'block';
        obj.oldText = obj.innerHTML;
        obj.innerHTML = 'Hide';
    }
}

function update_sharing(mode) {
    
    /*
		if (mode == 5)
    {
        document.getElementById('sharing_networks1_box').style.display = 'block';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
    else if (mode == 6)
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'block';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
    else if (mode == 8)
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'block';
    }
    else 
    {
        document.getElementById('sharing_networks1_box').style.display = 'none';
        document.getElementById('sharing_networks2_box').style.display = 'none';
        //document.getElementById('sharing_custom_box').style.display = 'none';
    }
    */
}

function update_updating(mode) {

    if (mode == 5)
    {
				document.getElementById('updating_somefriends_box').style.display = 'block';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
    else
    {
				document.getElementById('updating_somefriends_box').style.display = 'none';
        //document.getElementById('updating_custom_box').style.display = 'none';
    }
}

function add_updaterpermission_string(permission_string) {
    var f = document.getElementById('updating_permissions_list');
    
    if (!f.hasValues)
    {
        f.innerHTML = permission_string;
        f.hasValues = 'true';
    }    
    else
    {
        f.innerHTML = f.innerHTML + '<br/>' + permission_string;
    }
}


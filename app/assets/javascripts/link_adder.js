//which links are in the source box
var sourceMap = {};
//which links are in the target box
var targetMap = {};

//which links are clicked in the source box
var checkedSourceMap = {};
//which links are clicked in the target box
var checkedTargetMap = {};
//what has been moved to the target table
var addedLinks = {};
//hash of all the original objects with their selected status
var allLinks = {};
//the cell details for each object
var allLinksData = {};

//Move all from the target to source tables.
function addAll(resource_type, source) {

	if (source == "target") {
		for(var key in allLinks[resource_type]) {
			$(resource_type +"_" + key + "_target_row").hide();
			targetMap[resource_type][key] = false;
			sourceMap[resource_type][key] = true;
			checkedTargetMap[resource_type][key] = false;

			$(resource_type + "_" + key + "_source_row").show();
			changeColour(resource_type, key, "_target_cell", false);
			changeColour(resource_type, key, "_source_cell", false);
			allLinks[resource_type][key] = false;
		}
		removeChildren(resource_type +'_hidden');
		for (var key in targetMap[resource_type]) {
			if (targetMap[resource_type][key] == true) {
				var hidden_input = new Element('input',{'id':resource_type+'[]','name': resource_type+'[]','type':'hidden'});
				hidden_input.value = key;
				hidden_input.text = key;
				$(resource_type +'_hidden').insert(hidden_input);
			}
		}
	} else {
			for(var key in allLinks[resource_type]) {
				hide_row = resource_type +"_" + key + "_source_row";
				$(hide_row).hide();
				targetMap[resource_type][key] = true;
				sourceMap[resource_type][key] = false;
				checkedSourceMap[resource_type][key] = false;

				changeColour(resource_type, key, "_source_cell", false);
				$(resource_type + "_" + key + "_target_row").show();
				changeColour(resource_type, key, "_target_cell", false);
				allLinks[resource_type][key] = false;

			}
			removeChildren(resource_type +'_hidden');
			for (var key in targetMap[resource_type]) {
				if (targetMap[resource_type][key] == true) {
					var hidden_input = new Element('input',{'id':resource_type+'[]','name': resource_type+'[]','type':'hidden'});
					hidden_input.value = key;
					hidden_input.text = key;
					$(resource_type +'_hidden').insert(hidden_input);
				}
			}
	}
}

function addSelected(resource_type, source) {
	if (source == "target") {
		for(var key in checkedTargetMap[resource_type]) {
			if (allLinks[resource_type][key] == true) {

				$(resource_type +"_" + key + "_target_row").hide();
				targetMap[resource_type][key] = false;
				sourceMap[resource_type][key] = true;
				checkedTargetMap[resource_type][key] = false;

				$(resource_type + "_" + key + "_source_row").show();
				changeColour(resource_type, key, "_target_cell", false);
				changeColour(resource_type, key, "_source_cell", false);
				allLinks[resource_type][key] = false;
			}
	    }
		removeChildren(resource_type +'_hidden');
		for (var key in targetMap[resource_type]) {
			if (targetMap[resource_type][key] == true) {
				var hidden_input = new Element('input',{'id':resource_type +'[]','name': resource_type +'[]','type':'hidden'});
				hidden_input.value = key;
				hidden_input.text = key;
				$(resource_type +'_hidden').insert(hidden_input);
			}
		}
	} else {
		for(var key in checkedSourceMap[resource_type]) {
			 if (allLinks[resource_type][key] == true) {
				hide_row = resource_type + "_" + key + "_source_row";
				$(hide_row).hide();
				targetMap[resource_type][key] = true;
				sourceMap[resource_type][key] = false;
				checkedSourceMap[resource_type][key] = false;

				changeColour(resource_type, key, "_source_cell", false);
				$(resource_type + "_" + key + "_target_row").show();
				changeColour(resource_type, key, "_target_cell", false);
				allLinks[resource_type][key] = false;
			}
	    }
		removeChildren(resource_type +'_hidden');
		for (var key in targetMap[resource_type]) {
			if (targetMap[resource_type][key] == true) {
				var hidden_input = new Element('input',{'id':resource_type+'[]','name': resource_type+'[]','type':'hidden'});
				hidden_input.value = key;
				hidden_input.text = key;
				$(resource_type +'_hidden').insert(hidden_input);
			}
		}
	}
}

//when initialising keep a list of all the items for a
//resource type and their details
function addInstanceOfObject(resource_type, id, details) {
	var link_hash = allLinks[resource_type];
	if (link_hash == null) {
		link_hash = {};
		allLinks[resource_type] = link_hash;
		var source_map = {};
		checkedSourceMap[resource_type] = source_map;
		var in_source_map = {};
		sourceMap[resource_type] = in_source_map;
	}
	link_hash[id] = false;
	var link_data = allLinksData[resource_type];
	if (link_data == null) {
		link_data = {};
		allLinksData[resource_type] = link_data;
		var target_map = {};
		checkedTargetMap[resource_type] = target_map;
		var in_target_map = {};
		targetMap[resource_type] = in_target_map;
	}
	link_data[id] = details;
	//allLinks[id] = false;
	//allLinksData[id] = details;
}

//Change the background colour of the item depending
//on whether it is clicked or not
function changeColour (resource_type, id, source_or_target, change) {
	if (change){
		$(resource_type +"_"+id + source_or_target).setStyle({backgroundColor: '#900'});
	} else {
		$(resource_type +"_"+id + source_or_target).setStyle({backgroundColor: '#FFFFFF'});
	}
}

//Mark the item in the appropriate box box with id as being clicked/unclicked by changing its
//status in the checked Source/Target Map to true or false.
function checkItem(id, source, resource_type) {
	if (source == "target") {
		if (allLinks[resource_type][id] == true){
			checkedTargetMap[resource_type][id] = false;
			allLinks[resource_type][id] = false;
		} else {
			checkedTargetMap[resource_type][id] = true;
			allLinks[resource_type][id] = true;
		}
		changeColour(resource_type, id, "_target_cell", allLinks[resource_type][id]);
	} else {
		if (allLinks[resource_type][id] == true){
			checkedSourceMap[resource_type][id] = false;
			allLinks[resource_type][id] = false;
		} else {
			checkedSourceMap[resource_type][id] = true;
			allLinks[resource_type][id] = true;
		}
		changeColour(resource_type, id, "_source_cell", allLinks[resource_type][id]);
	}
}

function removeChildren(name) {
	$(name).childElements().each(function(e) {
	        e.remove();
	    });
}

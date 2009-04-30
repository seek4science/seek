// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults



function trimSpaces(str) {
    while ((str.length > 0) && (str.charAt(0) == ' '))
        str = str.substring(1);
    while ((str.length > 0) && (str.charAt(str.length - 1) == ' '))
        str = str.substring(0, str.length - 1);
    return str;
}

function addToolListTag(tag) {
    var tool_list = document.getElementById("tool_list").value;

    //check the tag doesn't already exist
    var tools_arr=tool_list.split(",")
    for (var i = 0; i < tools_arr.length; i++) {
        var current_tag = trimSpaces(tools_arr[i]);
        if (current_tag==tag) return;
    }

    if (trimSpaces(tool_list).length==0) {
        tool_list=tool_list+tag
    }
    else {
        tool_list=tool_list+", "+tag
    }
    
    document.getElementById("tool_list").value=tool_list;
}

function addOrganismListTag(tag) {

    var organisms_list = document.getElementById("organism_list").value;

    //check the tag doesn't already exist
    var expertise_arr=organisms_list.split(",")
    for (var i = 0; i < expertise_arr.length; i++) {
        var current_tag = trimSpaces(expertise_arr[i]);
        if (current_tag==tag) return;
    }

    if (trimSpaces(organisms_list).length==0) {
        organisms_list=organisms_list+tag
    }
    else {
        organisms_list=organisms_list+", "+tag
    }

    document.getElementById("organism_list").value=organisms_list;
}

function addExpertiseListTag(tag) {
    var expertise_list = document.getElementById("expertise_list").value;

    //check the tag doesn't already exist
    var expertise_arr=expertise_list.split(",")
    for (var i = 0; i < expertise_arr.length; i++) {
        var current_tag = trimSpaces(expertise_arr[i]);
        if (current_tag==tag) return;
    }

    if (trimSpaces(expertise_list).length==0) {
        expertise_list=expertise_list+tag
    }
    else {
        expertise_list=expertise_list+", "+tag
    }

    document.getElementById("expertise_list").value=expertise_list;
}

function checkNotInList(id,list) {
    rtn = true;

    for(var i = 0; i < list.length; i++)
        if(list[i][1] == id) {
            rtn = false;
            break;
        }

    return(rtn);
}

function clearList(name) {
    select=$(name)
    while(select.length>0) {
        select.remove(select.options[0])
    }
}

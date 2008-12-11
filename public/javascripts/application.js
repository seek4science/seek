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

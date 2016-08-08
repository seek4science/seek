function optionsFromArray(array) {
    var options = [];

    for(var i = 0; i < array.length; i++)
        options.push($j('<option/>').val(array[i][1]).text(array[i][0])[0]);

    return options;
}

function nestedOptionsFromJSONArray(array,prompt_option_text) {
    var options = [];
    options.push($j('<option/>').val(0).text(prompt_option_text));
    
    //gather together by parent id
    var parents = {};
    for(var i = 0; i < array.length; i++) {
        var item = array[i];
        if (parents[item.parent_id]) {
            var parent = parents[item.parent_id];
            parent.children.push({id:item.id,title:item.title})
        }
        else {
            var parent = {title:item.parent_title,id:item.parent_id,children:[]}
            parent.children.push({id:item.id,title:item.title});
            parents[item['parent_id']]=parent;
        }
    }

    //build into optgroups, with options clustered according to parent
    for (parent_id in parents) {
        var parent=parents[parent_id];
        console.log(parent);
        var group = $j('<optgroup/>').attr('label',parent.title);
        for(var i=0;i<parent.children.length;i++) {
            var child=parent.children[i];
            group.append($j('<option/>').val(child.id).text(child.title));
        }
        options.push(group);
    }

    return options;
}

function animateNode(node){
    var nodes = cy.$('node');
    var edges = cy.$('edge');
    deactivating_nodes(nodes);
    deactivating_edges(edges);
    activating_nodes(node);
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() == node.id()){
            activating_edges(edge);
            activating_nodes(target);
        }
        if (target.id() == node.id()){
            activating_edges(edge);
            activating_nodes(source);
        }
    });

    //need to call after processing all nodes and edges
    node.animate({
        css: { 'width':250, 'height':50 }
    }, {
        duration: 300
    })
    // set font style here for better animation (instead of in animate function).
    node.css('font-size', 14);
    node.css('font-weight', 'bolder');
}

function displayNodeInfo(node){
    //var html = "<span style='font-size:15px;font-weight:bolder;'>Chosen item:</span>";
    var html = "<h3>Chosen item</h3>"
    html += "<ul class='items'>";
    var node_data = node.data();
    html += '<li>';
    if (node_data.name == 'Hidden Item'){
        html += '<b>';
        html += node_data.name;
        html += '</b>';
    }else{
        html += '<a href=\''+ node_data.path +'\'>';
        html += '<b>';
        html += node_data.full_title;
        html += '</b>';
        html += "</a>";
    }
    html += '</li>';
    html += '</ul>';

    html += '<br/>';

    html += "<h3>Connected items</h3>";
    html += "<ul class='items'>";
    var connected_nodes = connectedNodes(node);
    for(var i=0;i<connected_nodes.length;i++){
        var node_data = connected_nodes[i].data();
        html += '<li>';
        if (node_data.name == 'Hidden Item'){
            html += node_data.name;
        }else{
            html += '<a href=\''+ node_data.path +'\'>';
            html += node_data.full_title;
            html += "</a>";
        }
        html += '</li>';
    }

    html += '</ul>';
    $('node_info').innerHTML = html;
}

function connectedNodes(node){
    var edges = cy.$('edge');
    var connected_nodes = [];
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() == node.id()){
            connected_nodes.push(target);
        }
        if (target.id() == node.id()){
            connected_nodes.push(source);
        }
    });
    return connected_nodes;
}

function activating_nodes(nodes){
    nodes.css('opacity', 1);
}

function activating_edges(edges){
    edges.css('opacity', 1);
}

function deactivating_nodes(nodes){
    nodes.css('opacity', 0.3);
    nodes.css('width',default_node_width);
    nodes.css('height',default_node_height);
    nodes.css('font-size',default_font_size);
    nodes.css('font-weight', 'normal');
}

function deactivating_edges(edges){
    edges.css('opacity', 0.2);
}

function animateNode(node){
    var nodes = cy.$('node');
    var edges = cy.$('edge');

    //first normalizing all nodes and fading all nodes and edges
    normalizingNodes(nodes);
    fadingNodes(nodes);
    fadingEdges(edges);

    //then appearing the chosen node and the connected nodes and edges
    appearingNodes(node);
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() == node.id()){
            appearingEdges(edge);
            appearingNodes(target);
        }
        if (target.id() == node.id()){
            appearingEdges(edge);
            appearingNodes(source);
        }
    });

    //then animate the chosen node
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
    var html = "<h3>Chosen item</h3>"
    html += "<ul class='items'>";
    var item_data = node.data();
    html += itemInfo(item_data);
    html += '</ul>';

    html += '<br/>';

    html += "<h3>Connected items</h3>";
    html += "<ul class='items'>";
    var connected_nodes = connectedNodes(node);
    for(var i=0;i<connected_nodes.length;i++){
        var item_data = connected_nodes[i].data();
        html += itemInfo(item_data);
    }

    html += '</ul>';
    $('node_info').innerHTML = html;
}

function itemInfo(item_data){
    html = '<li>';
    if (item_data.name == 'Hidden item'){
        html += item_data.full_title;
    }else{
        html += '<a href=\''+ item_data.path +'\'>';
        html += item_data.full_title;
        html += "</a>";
    }
    html += '</li>';
    return html;
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

function processPanzoom() {
    //display panzoom
    $j('#cy').cytoscapePanzoom();

    alignPanzoomCenteredVertical();

    //reset on panzoom also reset all nodes and edges css
    $j('.ui-cytoscape-panzoom-reset').click(function () {
        var nodes = cy.$('node')
        normalizingNodes(nodes);
        appearingNodes(nodes);
        appearingEdges(cy.$('edge'));
    });
}

function alignPanzoomCenteredVertical(){
    var graph_height = cy.container().style.height.split('px')[0];
    var panzoom_height = 230;
    var panzoom_position = (graph_height - panzoom_height)/2;
    var panzoom = $j('.ui-cytoscape-panzoom')[0];
    panzoom.style['top']=panzoom_position+'px'


}

function appearingNodes(nodes){
    nodes.css('opacity', 1);
}

function appearingEdges(edges){
    edges.css('opacity', 1);
}

function fadingNodes(nodes){
    nodes.css('opacity', 0.3);
}

function fadingEdges(edges){
    edges.css('opacity', 0.2);
}

function normalizingNodes(nodes){
    nodes.css('width',default_node_width);
    nodes.css('height',default_node_height);
    nodes.css('font-size',default_font_size);
    nodes.css('font-weight', 'normal');
}

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
        if (source.id() === node.id()){
            appearingEdges(edge);
            appearingNodes(target);
        }
        if (target.id() === node.id()){
            appearingEdges(edge);
            appearingNodes(source);
        }
    });

    //then animate the chosen node
    node.animate({
        css: { 'width':250, 'height':50 }
    }, {
        duration: 300
    });
    // set font style here for better animation (instead of in animate function).
    node.css('font-size', 14);
    node.css('font-weight', 'bolder');
    if (node.data().name !== 'Hidden item')
        node.css('color', '#0000e5');
    node.select();
}

function displayNodeInfo(node){
    var html = "<h3>Chosen item</h3>";
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

    var node_info = $('node_info');
    $('node_info').innerHTML = html;

    //can not use Effect.Appear here, it does not activate clientHeight
    node_info.style['display'] = 'block';
    alignCenterVertical(node_info, node_info.clientHeight);
}

function itemInfo(item_data){
    html = '<li>';
    html += item_data.item_info;
    html += '</li>';
    return html;
}

function connectedNodes(node){
    var edges = cy.$('edge');
    var connected_nodes = [];
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() === node.id()){
            connected_nodes.push(target);
        }
        if (target.id() === node.id()){
            connected_nodes.push(source);
        }
    });
    return connected_nodes;
}


function targetNodeCollection(node){
    var edges = cy.$('edge');
    var target_node_collection = cy.collection();
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() === node.id()){
            target_node_collection = target_node_collection.add(target);
        }
    });
    return target_node_collection;
}

function sourceNodeCollection(node){
    var edges = cy.$('edge');
    var source_node_collection = cy.collection();
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (target.id() === node.id()){
            source_node_collection = source_node_collection.add(source);
        }
    });
    return source_node_collection;
}

function edgeToTargetCollection(node){
    var edges = cy.$('edge');
    var edge_to_target_collection = cy.collection();
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (source.id() === node.id()){
            edge_to_target_collection = edge_to_target_collection.add(edge);
        }
    });
    return edge_to_target_collection;
}

function edgeToSourceCollection(node){
    var edges = cy.$('edge');
    var edge_to_source_collection = cy.collection();
    edges.each(function(i, edge){
        var source = edge.source();
        var target =edge.target();
        if (target.id() === node.id()){
            edge_to_source_collection = edge_to_source_collection.add(edge);
        }
    });
    return edge_to_source_collection;
}

function processPanzoom() {
    //display panzoom
    $j('#cy').cytoscapePanzoom({
        panSpeed: 1
    });

    //set again the graph height if panzoom height is bigger
    var panzoom_height = 220;
    var graph_height = cy.container().style.height.split('px')[0];
    cy.container().style.height = Math.max(graph_height, panzoom_height) +'px';

    alignCenterVertical($j('.ui-cytoscape-panzoom')[0], panzoom_height);


    //reset on panzoom also reset all nodes and edges css
    $j('.ui-cytoscape-panzoom-reset').click(function () {
        var nodes = cy.$('node')
        normalizingNodes(nodes);
        appearingNodes(nodes);
        appearingEdges(cy.$('edge'));
        Effect.Fade('node_info', { duration: 0.25 });
    });
}

function alignCenterVertical(element, element_height){
    var graph_height = cy.container().style.height.split('px')[0];
    var distance_from_top = (graph_height - element_height)/2;
    if (distance_from_top > 0){
        element.style['top']=distance_from_top+'px';
    }else{
        element.style['top']='0px';
    }
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
    nodes.css('color',default_color);
    nodes.unselect();
}

function resizeGraph(){
    cy.fit(50);
    if (cy.zoom() > 1){
        cy.reset();
        cy.center();
    }
}

function labelPosition(node){
    var label_pos = new Object();
    var graph_pos = $j('#cy')[0].getBoundingClientRect();
    var node_posX = node.renderedPosition().x + graph_pos.left;
    var node_posY = node.renderedPosition().y + graph_pos.top;
    var font_size = node.renderedCss()['font-size'];
    var label = node.data().name;
    var ruler = $j('#ruler')[0];
    ruler.style.fontSize = font_size;
    ruler.style.fontWeight = 'bolder';
    ruler.innerHTML = label;
    var zoom_level = cy.zoom();
    var label_width = ruler.offsetWidth + 2*zoom_level;
    var label_height = ruler.offsetHeight;
    label_pos.minX = node_posX - label_width/2;
    label_pos.maxX = node_posX + label_width/2;
    label_pos.minY = node_posY - label_height/2;
    label_pos.maxY = node_posY + label_height/2;
    return label_pos;
}

function mouseOnLabel(node, mouse_event){
    var label_pos = labelPosition(node);
    var mouse_posX = mouse_event.clientX;
    var mouse_posY = mouse_event.clientY;
    var mouse_on_label = mouse_posX > label_pos.minX && mouse_posX < label_pos.maxX && mouse_posY > label_pos.minY && mouse_posY < label_pos.maxY;
    return mouse_on_label;
}

function clickLabelLink(node, mouse_event){
    if (node.data().name !== "Hidden item"){
        if (mouseOnLabel(node, mouse_event)){
            var link = document.createElement('a');
            link.href = node.data().item_info.split('"')[1];
            clickLink(link);
        }
    }
}

function disableMouseWheel(){
    var canvas_render = cy.renderer();
    var bindings = canvas_render.bindings;
    for( var i=0; i<bindings.length; i++){
        binding = bindings[i];
        var event = binding.event;
        if (event.match(/wheel/i) != null || event.match(/scroll/i) !=null){
            binding.target.removeEventListener(event, binding.handler, binding.useCapture);
        }
    }
}

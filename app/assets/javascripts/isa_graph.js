var cy;
var default_node_width = 250;
var default_node_height = 65;
var default_font_size = 16;
var default_color = '#323232';
var default_text_max_width = 245;

jQuery.noConflict();
var $j = jQuery;

function drawGraph(elements, current_element_id){
    cy=cytoscape({
        container: document.getElementById('cy'),
        showOverlay: false,

        layout: {
            name: 'breadthfirst',
            directed: true
        },

        style: cytoscape.stylesheet()
            .selector('node')
            .css({
                'shape': 'roundrectangle',
                'border-color': 'data(borderColor)',
                'border-width': 2,
                'das': 'mapData(weight, 40, 80, 20, 60)',
                'content': 'data(name)',
                'text-valign': 'center',
                'text-outline-width': 1,
                'text-outline-color': 'data(faveColor)',
                'background-color': 'data(faveColor)',
                'color':default_color,
                'width':default_node_width,
                'height':default_node_height,
                'font-size':default_font_size,
                'text-wrap': 'wrap',
                'text-max-width': default_text_max_width
            })

            .selector('edge')
            .css({
                'width': 1.5,
                'target-arrow-shape': 'none',
                'line-color': '#191975',
                'source-arrow-color': 'data(faveColor)',
                'target-arrow-color': 'data(faveColor)',
                'content': 'data(name)',
                'color': '#222222',
                'text-background-color': '#eeeeff',
                'text-background-shape': 'roundrectangle',
                'text-background-opacity': 0.7,
                'text-border-width': 1,
                'text-border-style': 'solid',
                'text-border-color': '#ccccdd',
                'text-border-opacity': 0.7,
                'font-size': (default_font_size)
            }),

        elements: elements,

        ready: function(){
            cy = this;
            var nodes = cy.$('node');

            //process only when having nodes
            if (nodes.length > 0){
                //processPanzoom();

                nodes.on('click', function(e){
                    var node = e.cyTarget;
                    if(node.selected() === true){
                        clickLabelLink(node, e.originalEvent);
                    }else{
                        animateNode(node);
                        displayNodeInfo(node);
                    }
                });

                //animate the current node
                var current_node = cy.nodes('[id=\''+ current_element_id +'\']')[0];
                animateNode(current_node);
                displayNodeInfo(current_node);

                //disableMouseWheel();
                resizeGraph();
                //need put zoom after resizeGraph, otherwise fit() does not work
                cy.zoomingEnabled(false);
            }else{
                $j('.isa_graph')[0].hide();
            }
        }
    });
}


function animateNode(node){
    var nodes = cy.$('node');
    var edges = cy.$('edge');

    var excluded_selected_nodes = [];
    for (var i=0; i<nodes.length; i++){
        var node_tmp = nodes[i];
        if (node_tmp.data().id !== node.data().id)
            excluded_selected_nodes.push(node_tmp);
    }

    //first normalizing all nodes and fading all nodes and edges
    normalizingNodes(excluded_selected_nodes);

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

    node.animate({
        css: { 'width':default_node_width+35, 'height':default_node_height+15 }
    }, {
        duration: 300
    });
    
    node.css({
        'font-size': default_font_size,
        'text-max-width': default_text_max_width+15
    });

    if (node.data().name !== 'Hidden item'){
        node.css({'color': '#0000e5'});
    }
    node.select();
}

function displayNodeInfo(node){

    html = "<div class='isa-selected-item'><strong>Selected item: </strong>";
    var item_data = node.data();
    html += itemInfo(item_data);
    html += '</div>';

    var node_info = $('node_info');
    $('node_info').innerHTML = html;


}


function itemInfo(item_data){
    var html = '<span>';
    html += item_data.item_info;
    html += '</span>';
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
        var nodes = cy.$('node');
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
        element.style.top=distance_from_top+'px';
    }else{
        element.style.top='0px';
    }
}

function appearingNodes(nodes){
    nodes.css({'opacity': 1});
}

function appearingEdges(edges){
    edges.css({'opacity': 1});
}

function fadingNodes(nodes){
    nodes.css({'opacity': 0.6});
}

function fadingEdges(edges){
    edges.css({'opacity': 0.5});
}

function normalizingNodes(nodes){
    for (var i=0; i<nodes.length; i++){
        var node = nodes[i];
        node.css({
            'width': default_node_width,
            'height': default_node_height,
            'font-size': default_font_size,
            'font-weight': 'normal',
            'color': default_color,
            'text-max-width': default_text_max_width
        });
        node.unselect();

    }
}

function resizeGraph(){
    cy.fit(50);
    if (cy.zoom() > 1){
        cy.reset();
        cy.center();
    }
}

function labelPosition(node, label_part, line_index, total_line){
    var label_pos = {};
    var graph_pos = $j('#cy')[0].getBoundingClientRect();
    var node_posX = node.renderedPosition().x + graph_pos.left;
    var node_posY = node.renderedPosition().y + graph_pos.top;
    var font_size = node.renderedCss()['font-size'];
    var ruler = $j('#ruler')[0];
    ruler.style.fontSize = font_size;
    ruler.style.fontWeight = 'bolder';
    ruler.innerHTML = label_part;    
    var label_width = ruler.offsetWidth;
    var label_height = ruler.offsetHeight;
    label_pos.minX = node_posX - label_width/2;
    label_pos.maxX = node_posX + label_width/2;
    label_pos.maxY = node_posY + (line_index - total_line/2)*label_height;
    label_pos.minY = label_pos.maxY - label_height;
    
    return label_pos;
}

function labelLines(node){
    var label = node.data().name;
    var font_size = node.renderedCss()['font-size'];
    var ruler = $j('#ruler')[0];
    ruler.style.fontSize = font_size;
    //ruler.style.fontWeight = 'bolder';
    ruler.innerHTML = label;    
    var label_width = ruler.offsetWidth;
    var text_max_width = node.renderedCss()['text-max-width'];
    var max_width = text_max_width.split('px')[0];
    var max_width_integer = parseInt(max_width);
    var lines = [];
    if (label_width > max_width_integer){
        var words = label.split(' ');
        var line = '';
        for( var i=0; i<words.length; i++){
            var testLine = line + words[i] + ' ';
            ruler.innerHTML = testLine;
            var testWidth = ruler.offsetWidth;
            if (testWidth > max_width_integer && i > 0) {
                lines.push(line.trim());
                line = words[i] + ' ';
            }
            else {
                line = testLine;
            }
            //when last word, push line to lines
            if (i === words.length-1){
                lines.push(line.trim());
            }
        }
    }else{
        lines.push(label);
    }
    return lines;
}

function mouseOnLabel(node, mouse_event){
    var lines = labelLines(node);
    var mouse_on_label = false;
    for (var i=0; i<lines.length; i++){
    	var label_pos = labelPosition(node, lines[i], i+1, lines.length);
    	var mouse_posX = mouse_event.clientX;
    	var mouse_posY = mouse_event.clientY;
	    mouse_on_label = mouse_posX > label_pos.minX && mouse_posX < label_pos.maxX && mouse_posY > label_pos.minY && mouse_posY < label_pos.maxY;
        if (mouse_on_label === true){
	        return mouse_on_label;
	    }
    }

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
        if (event.match(/wheel/i) !== null || event.match(/scroll/i) !==null){
            binding.target.removeEventListener(event, binding.handler, binding.useCapture);
        }
    }
}

function decodeHTMLForElements(elements){
    for( var i=0; i<elements.length; i++){
        elements[i].data.name = decodeHTML(elements[i].data.name);
        elements[i].data.item_info = decodeHTML(elements[i].data.item_info);
    }
}

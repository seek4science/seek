var cy;
var default_node_width = 200;
var default_node_height = 65;
var default_font_size = 16;
var default_color = '#323232';
var default_text_max_width = 195;
var background_image_size = default_node_height - 10;
var originNode;

jQuery.noConflict();
var $j = jQuery;

function drawGraph(elements, current_element_id){
    cy=cytoscape({
        container: document.getElementById('cy'),

        userZoomingEnabled: false,
        panningEnabled: true,
        userPanningEnabled: true,

        layout: {
            name: 'breadthfirst',
            directed: true,
            spacingFactor: 1.25,
            padding: 50
        },

        style: [
            {
                selector: 'node',
                css: {
                    'shape': 'roundrectangle',
                    'border-color': 'data(borderColor)',
                    'border-width': 2,
                    'das': 'mapData(weight, 40, 80, 20, 60)',
                    'content': 'data(name)',
                    'text-valign': 'center',
                    'text-outline-width': 1,
                    'text-outline-color': 'data(faveColor)',
                    'background-color': 'data(faveColor)',
                    // The following is a hacky way of making sure the image doesn't overlap the text
                    'padding-left': background_image_size + 10,
                    'padding-right': background_image_size + 10,
                    'color': default_color,
                    'width': default_node_width,
                    'height': default_node_height,
                    'font-size': default_font_size,
                    'text-wrap': 'wrap',
                    'text-max-width': default_text_max_width,
                    'opacity': 0.6
                }
            },
            {
                selector: 'node[imageUrl]',
                css: {
                    'background-image': 'data(imageUrl)',
                    'background-width': background_image_size,
                    'background-height': background_image_size,
                    // The following is a hacky way of making sure the image doesn't overlap the text
                    'background-position-x': -background_image_size,
                    'background-position-y': '50%'
                }
            },
            {
                selector: 'edge',
                css: {
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
                    'font-size': (default_font_size),
                    'opacity': 0.5
                }
            },
            {
                selector: '.connected',
                css: {
                    'opacity': 1
                }
            },
            {
                selector: '.selected', // Note this is not the same as cytoscape's ':selected'
                css: {
                    'font-weight': 'bold',
                    'font-size': default_font_size,
                    'text-max-width': default_text_max_width + 15,
                    'width': default_node_width + 35,
                    'height': default_node_height + 15,
                    'transition-property': 'width, height',
                    'transition-duration': 300,
                    'opacity': 1
                }
            }
        ],
        elements: elements,

        ready: function(){
            var nodes = cy.$('node');

            //process only when having nodes
            if (nodes.length > 0){
                //animate the current node
                originNode = cy.nodes('[id=\''+ current_element_id +'\']')[0];
                originNode.select();
                cy.animate({ zoom: 0.75, center: { eles: originNode } });
            }else{
                $j('.isa_graph')[0].hide();
            }
        }
    });
    cy.panzoom({
        panSpeed: 1,
        zoomInIcon: 'glyphicon glyphicon-plus',
        zoomOutIcon: 'glyphicon glyphicon-minus',
        resetIcon: 'glyphicon glyphicon-resize-full'
    });

    cy.on('tap', 'node:selected', function (event) {
        if(event.cyTarget != originNode && event.cyTarget.data('url'))
            window.location = event.cyTarget.data('url');
    });

    cy.on('select', 'node', function (event) {
        animateNode(event.cyTarget);
        displayNodeInfo(event.cyTarget);
    });
}

function animateNode(node){
    //first normalizing all nodes and fading all nodes and edges
    cy.$('node.connected').removeClass('connected');
    cy.$('edge.connected').removeClass('connected');

    //then appearing the chosen node and the connected nodes and edges
    node.addClass('connected');
    node.connectedEdges().addClass('connected');
    node.connectedEdges().connectedNodes().addClass('connected');

    // Animate the selected node
    cy.$('node.selected').removeClass('selected');
    node.addClass('selected');

    // Center the view on the node
    cy.animate({ center: { eles: cy.$(':selected') } });
}

function displayNodeInfo(node) {
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

function decodeHTMLForElements(elements){
    for( var i=0; i<elements.length; i++){
        elements[i].data.name = decodeHTML(elements[i].data.name);
        elements[i].data.item_info = decodeHTML(elements[i].data.item_info);
    }
}

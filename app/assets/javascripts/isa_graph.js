var cy;

var ISA = {
    originNode: null,

    defaults: {
        nodeWidth: 200,
        nodeHeight: 65,
        fontSize: 16,
        color: '#323232',
        textMaxWidth: 195,
        backgroundImageSize: 50
    },

    drawGraph: function (elements, current_element_id) {
        cy = window.cy = cytoscape({
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
                        'padding-left': ISA.defaults.backgroundImageSize + 10,
                        'padding-right': ISA.defaults.backgroundImageSize + 10,
                        'color': ISA.defaults.color,
                        'width': ISA.defaults.nodeWidth,
                        'height': ISA.defaults.nodeHeight,
                        'font-size': ISA.defaults.fontSize,
                        'text-wrap': 'wrap',
                        'text-max-width': ISA.defaults.textMaxWidth,
                        'opacity': 0.6
                    }
                },
                {
                    selector: 'node[imageUrl]',
                    css: {
                        'background-image': 'data(imageUrl)',
                        'background-width': ISA.defaults.backgroundImageSize,
                        'background-height': ISA.defaults.backgroundImageSize,
                        // The following is a hacky way of making sure the image doesn't overlap the text
                        'background-position-x': -ISA.defaults.backgroundImageSize,
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
                        'font-size': ISA.defaults.fontSize,
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
                        'text-max-width': ISA.defaults.textMaxWidth + 15,
                        'width': ISA.defaults.nodeWidth + 35,
                        'height': ISA.defaults.nodeHeight + 15,
                        'transition-property': 'width, height',
                        'transition-duration': 300,
                        'opacity': 1
                    }
                }
            ],
            elements: elements,

            ready: function () {
                var nodes = cy.$('node');

                //process only when having nodes
                if (nodes.length > 0) {
                    //animate the current node
                    ISA.originNode = cy.nodes('[id=\'' + current_element_id + '\']')[0];
                    ISA.originNode.select();
                    cy.animate({zoom: 0.75, center: {eles: ISA.originNode}});
                } else {
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
            if (event.cyTarget != ISA.originNode && event.cyTarget.data('url'))
                window.location = event.cyTarget.data('url');
        });

        cy.on('select', 'node', function (event) {
            ISA.animateNode(event.cyTarget);
            ISA.displayNodeInfo(event.cyTarget);
        });
    },

    animateNode: function (node) {
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
        cy.animate({center: {eles: cy.$(':selected')}});
    },

    displayNodeInfo: function (node) {
        $j('#node_info').html(HandlebarsTemplates['isa/item_info'](node.data()));
    },

    decodeHTMLForElements: function (elements) {
        for (var i = 0; i < elements.length; i++) {
            elements[i].data.name = decodeHTML(elements[i].data.name);
        }
    }
};

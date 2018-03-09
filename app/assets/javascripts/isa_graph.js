var cy;

var ISA = {
    originNode: null,

    defaults: {
        nodeWidth: 200,
        nodeHeight: 65,
        fontSize: 16,
        smallerFontSize: 15,
        color: '#323232',
        textMaxWidth: 195,
        backgroundImageSize: 50,
        layout: {
            name: 'breadthfirst',
            directed: true,
            spacingFactor: 1.25,
            padding: 50
        },
        animationDuration: 300
    },

    drawGraph: function (elements, current_element_id) {
        cy = window.cy = cytoscape({
            container: document.getElementById('cy'),

            userZoomingEnabled: false,
            panningEnabled: true,
            userPanningEnabled: true,
            maxZoom: 2,

            layout: ISA.defaults.layout,

            style: [
                {
                    selector: 'node.resource',
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
                        'font-size': function (el) {
                            return el.data('name').length > 60 ? ISA.defaults.smallerFontSize : ISA.defaults.fontSize;
                        },
                        'text-wrap': 'wrap',
                        'text-max-width': ISA.defaults.textMaxWidth,
                        'opacity': 0.6
                    }
                },
                {
                    selector: 'node.child-count',
                    css: {
                        'shape': 'roundrectangle',
                        'content': 'data(name)',
                        'text-valign': 'center',
                        'background-color': '#eeeeee',
                        'width': ISA.defaults.nodeWidth,
                        'font-size': ISA.defaults.fontSize,
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
                        'line-color': '#bbb',
                        'opacity': 0.5
                    }
                },
                {
                    selector: 'edge.resource-edge',
                    css: {
                        'width': 1.5,
                        'target-arrow-shape': 'none',
                        'line-color': '#191975',
                        'source-arrow-color': '#71b7be',
                        'target-arrow-color': '#71b7be',
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
                    cy.animate({ zoom: 0.8, center: {eles: ISA.originNode}, duration: ISA.defaults.animationDuration });
                } else {
                    $j('#isa-graph').hide();
                }
            }
        });

        cy.panzoom({
            panSpeed: 1,
            zoomInIcon: 'glyphicon glyphicon-plus',
            zoomOutIcon: 'glyphicon glyphicon-minus',
            resetIcon: 'glyphicon glyphicon-resize-full',
            maxZoom: 2
        });

        cy.on('tap', 'node.resource:selected', function (event) {
            if (ISA.recentlyClickedNode) {
                ISA.visitNode(event.cyTarget);
                ISA.recentlyClickedNode = null;
            } else {
                // Remember the click for half a second, so we can treat a follow-up click as a double click
                ISA.rememberFirstClick(event.cyTarget);
            }
        });

        cy.on('select', 'node.resource', function (event) {
            ISA.selectNode(event.cyTarget);
            ISA.rememberFirstClick(event.cyTarget);
        });

        cy.on('select', 'node.child-count', function (event) {
           ISA.loadChildren(event.cyTarget);
        });
    },

    selectNode: function (node) {
        var jsTree = $j('#jstree').jstree(true);
        jsTree.deselect_all();
        $j('li[data-node-id=' + node.data('id') +']').each(function () {
            jsTree.select_node(this.id);
        });
        ISA.animateNode(node, 0.8);
        ISA.displayNodeInfo(node);
    },

    highlightNode: function (node) {
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
    },

    animateNode: function (node, zoom) {
        ISA.highlightNode(node);
        // Center the view on the node
        opts = { center: { eles: node }, duration: ISA.defaults.animationDuration };
        if (zoom)
            opts.zoom = zoom;
        cy.animate(opts);
    },

    displayNodeInfo: function (node) {
        $j('#node_info').html(HandlebarsTemplates['isa/item_info'](node.data()));
    },

    decodeHTMLForElements: function (elements) {
        for (var i = 0; i < elements.length; i++) {
            elements[i].data.name = decodeHTML(elements[i].data.name);
        }
    },

    fullscreen: function (state) {
        $j('#isa-graph').toggleClass('fullscreen', state);
        cy.resize();
    },

    recentlyClickedNode: null,
    rememberFirstClick: function (target) {
        ISA.recentlyClickedNode = target;
        setTimeout(function () {
            ISA.recentlyClickedNode = null;
        }, 500);
    },

    getNode: function (id) {
        return cy.$('#' + id);
    },

    visitNode: function (node) {
        if (node != ISA.originNode && node.data('url')) {
            window.location = node.data('url');
        }
    },

    eachTreeNodeElement: function (id, callback) {
        $j('li[data-node-id=' + id +']').each(callback);
    },

    eachTreeNode: function (id, callback) {
        ISA.eachTreeNodeElement(function () {
            var treeNode = tree.get_node(this.id);
            callback.apply(treeNode);
        });
    },

    getTreeNodes: function (id) {
        var nodes = [];
        ISA.eachTreeNode(id, function () {
            nodes.push(treeNode);
        });

        return nodes;
    },

    loadChildren: function (childCountNode) { // This argument is a cytoscape node!
        var tree = $j('#jstree').jstree(true);

        // Show a spinner on the tree nodes
        ISA.eachTreeNodeElement(childCountNode.id(), function () {
            $j(this).spinner('add');
        });

        $j.ajax({
            url: childCountNode.data('url'),
            success: function (data) {
                var node = childCountNode.incomers().sources();

                ISA.decodeHTMLForElements(data.cytoscape);

                // Set the child node positions to be on top of the node
                data.cytoscape.forEach(function (childNode) {
                    childNode.renderedPosition = node.renderedPosition();
                });
                cy.add(data.cytoscape);
                cy.remove(childCountNode);

                // Adjust the cytoscape layout to fit in the new nodes
                cy.layout($j.extend({
                        fit: false,
                        animate: true,
                        animationDuration: ISA.defaults.animationDuration,
                        stop: function () {
                            ISA.highlightNode(node);
                            cy.animate({ fit: { eles: node.union(node.outgoers().targets()), padding: 40 },
                                duration: ISA.defaults.animationDuration });
                        }
                    }, ISA.defaults.layout)
                );

                // Delete the "show x more" node
                ISA.eachTreeNodeElement(childCountNode.id(), function () {
                    tree.delete_node(this.id);
                });

                // Add the nodes to the JStree
                ISA.eachTreeNodeElement(node.id(), function (index) {
                    var treeNode = tree.get_node(this.id);

                    treeNode.state.loaded = true;
                    treeNode.state.opened = true;

                    // We iterate backwards because parent nodes seem to appear after child nodes in the list, which breaks
                    //  jstree
                    for (var i = data.jstree.length - 1; i >= 0; i--) {
                        var childNode = data.jstree[i];

                        // Only add the node to the tree if its not already there
                        if (!$j('li[data-node-id=' + childNode.li_attr['data-node-id'] +']', this).length) {
                            childNode.id = childNode.id + index; // To stop dupes!
                            tree.create_node(treeNode, childNode);
                        }
                    }

                    // Need to do this due to a little hack we used when drawing the tree
                    //  (to show a node as "openable" despite having no children)
                    tree.redraw_node(this.id);
                });

                cy.resize();
            }
        });
    }
};

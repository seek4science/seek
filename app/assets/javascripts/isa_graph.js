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
    if (node.data().name != 'Hidden item')
        node.css('color', '#0000e5');
    node.select();
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

    var node_info = $('node_info');
    $('node_info').innerHTML = html;

    //can not use Effect.Appear here, it does not activate clientHeight
    node_info.style['display'] = 'block';
    alignCenterVertical(node_info, node_info.clientHeight);
}

function itemInfo(item_data){
    html = '<li>';
    if (item_data.name == 'Hidden item'){
        html += item_data.hidden_item_info;
    }else{
        html += item_data.link;
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
    if (mouseOnLabel(node, mouse_event)){
        var link = document.createElement('a');
        link.href = node.data().link.split('"')[1];
        clickLink(link);
    }
}

/*
    The following part is to modify the default behavior of cytoscape
*/

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

// This jquery function is to overide the cytoscape BreadthFirstLayout
(function($$){
    var defaults = {
        fit: true, // whether to fit the viewport to the graph
        ready: undefined, // callback on layoutready
        stop: undefined, // callback on layoutstop
        directed: true, // whether the tree is directed downwards (or edges can point in any direction if false)
        padding: 30, // padding on fit
        circle: false, // put depths in concentric circles if true, put depths top down if false
        roots: undefined // the roots of the trees
    };

    function BreadthFirstLayout( options ){
        this.options = $$.util.extend({}, defaults, options);
    }

    BreadthFirstLayout.prototype.run = function(){
        var params = this.options;
        var options = params;

        var cy = params.cy;
        var nodes = cy.nodes();
        var edges = cy.edges();
        var container = cy.container();

        //var width = container.clientWidth;
        //var height = container.clientHeight;

        var roots;
        if( $$.is.elementOrCollection(options.roots) ){
            roots = options.roots;
        } else if( $$.is.array(options.roots) ){
            var rootsArray = [];

            for( var i = 0; i < options.roots.length; i++ ){
                var id = options.roots[i];
                var ele = cy.getElementById( id );
                roots.push( ele );
            }

            roots = new $$.Collection( cy, rootsArray );
        } else {
            roots = nodes.roots();
        }


        var depths = [];
        var foundByBfs = {};
        var id2depth = {};

        // find the depths of the nodes
        roots.bfs(function(i, depth){
            var ele = this[0];

            if( !depths[depth] ){
                depths[depth] = [];
            }

            depths[depth].push( ele );
            foundByBfs[ ele.id() ] = true;
            id2depth[ ele.id() ] = depth;
        }, options.directed);

        // check for nodes not found by bfs
        var orphanNodes = [];
        for( var i = 0; i < nodes.length; i++ ){
            var ele = nodes[i];

            if( foundByBfs[ ele.id() ] ){
                continue;
            } else {
                orphanNodes.push( ele );
            }
        }

        // assign orphan nodes a depth from their neighborhood
        var maxChecks = orphanNodes.length * 3;
        var checks = 0;
        while( orphanNodes.length !== 0 && checks < maxChecks ){
            var node = orphanNodes.shift();
            var neighbors = node.neighborhood().nodes();
            var assignedDepth = false;

            for( var i = 0; i < neighbors.length; i++ ){
                var depth = id2depth[ neighbors[i].id() ];

                if( depth !== undefined ){
                    depths[depth].push( node );
                    assignedDepth = true;
                    break;
                }
            }

            if( !assignedDepth ){
                orphanNodes.push( node );
            }

            checks++;
        }

        // assign orphan nodes that are still left to the depth of their subgraph
        while( orphanNodes.length !== 0 ){
            var node = orphanNodes.shift();
            var subgraph = node.bfs();
            var assignedDepth = false;

            for( var i = 0; i < subgraph.length; i++ ){
                var depth = id2depth[ subgraph[i].id() ];

                if( depth !== undefined ){
                    depths[depth].push( node );
                    assignedDepth = true;
                    break;
                }
            }

            if( !assignedDepth ){ // worst case if the graph really isn't tree friendly, then just dump it in 0
                if( depths.length === 0 ){
                    depths.push([]);
                }

                depths[0].push( node );
            }
        }

        // assign the nodes a depth and index
        function assignDepthsToEles(){
            for( var i = 0; i < depths.length; i++ ){
                var eles = depths[i];

                for( var j = 0; j < eles.length; j++ ){
                    var ele = eles[j];

                    ele._private.scratch.BreadthFirstLayout = {
                        depth: i,
                        index: j
                    };
                }
            }
        }
        assignDepthsToEles();

        // find min distance we need to leave between nodes
        var minDistance = 0;
        for( var i = 0; i < nodes.length; i++ ){
            var w = nodes[i].outerWidth();
            var h = nodes[i].outerHeight();

            minDistance = Math.max(minDistance, w, h);
        }
        minDistance *= 1.75; // just to have some nice spacing

        // get the weighted percent for an element based on its connectivity to other levels
        var cachedWeightedPercent = {};
        function getWeightedPercent( ele ){
            if( cachedWeightedPercent[ ele.id() ] ){
                return cachedWeightedPercent[ ele.id() ];
            }

            var eleDepth = ele._private.scratch.BreadthFirstLayout.depth;
            var neighbors = ele.neighborhood().nodes();
            var percent = 0;
            var samples = 0;

            for( var i = 0; i < neighbors.length; i++ ){
                var neighbor = neighbors[i];
                var nEdges = neighbor.edgesWith( ele );
                var index = neighbor._private.scratch.BreadthFirstLayout.index;
                var depth = neighbor._private.scratch.BreadthFirstLayout.depth;
                var nDepth = depths[depth].length;

                if( eleDepth > depth || eleDepth === 0 ){ // only get influenced by elements above
                    percent += index / nDepth;
                    samples++;
                }
            }

            samples = Math.max(1, samples);
            percent = percent / samples;

            if( samples === 0 ){ // so lone nodes have a "don't care" state in sorting
                percent = undefined;
            }

            cachedWeightedPercent[ ele.id() ] = percent;
            return percent;
        }

        // rearrange the indices in each depth level based on connectivity
        for( var times = 0; times < 3; times++ ){ // do it a few times b/c the depths are dynamic and we want a more stable result

            for( var i = 0; i < depths.length; i++ ){
                var depth = i;
                var newDepths = [];

                depths[i] = depths[i].sort(function(a, b){
                    var apct = getWeightedPercent( a );
                    var bpct = getWeightedPercent( b );


                    return apct - bpct;
                });
            }
            assignDepthsToEles(); // and update

        }

        var center = {
            x: width/2,
            y: height/2
        };
        nodes.positions(function(){
            var ele = this[0];
            var info = ele._private.scratch.BreadthFirstLayout;
            var depth = info.depth;
            var index = info.index;

            var width = container.clientWidth;
            //calculate the height dynamically
            var height = graphHeight();
            container.style.height = height+'px';

            function graphHeight(){
                var max_index = 0;
                for (var i=0;i<depths.length;i++){
                    max_index = Math.max(depths[i].length, max_index);
                }
                return (2*max_index + 1)*nodes[0].outerHeight();
            }

            var distanceX = Math.max(width / (depths.length + 1), minDistance );
            var distanceY = height / (depths[depth].length + 1);
            var radiusStepSize = Math.min( width / 2 / depths.length, height / 2 / depths.length );
            radiusStepSize = Math.max( radiusStepSize, minDistance );

            if( options.circle ){
                var radius = radiusStepSize * depth + radiusStepSize - (depths.length > 0 && depths[0].length <= 3 ? radiusStepSize/2 : 0);
                var theta = 2 * Math.PI / depths[depth].length * index;

                if( depth === 0 && depths[0].length === 1 ){
                    radius = 1;
                }

                return {
                    x: center.x + radius * Math.cos(theta),
                    y: center.y + radius * Math.sin(theta)
                };

            } else {
                return {
                    y: (index + 1) * distanceY,
                    x: (depth + 1) * distanceX
                };
            }

        });

        if( params.fit ){
            cy.fit( options.padding );
        }

        cy.one("layoutready", params.ready);
        cy.trigger("layoutready");

        cy.one("layoutstop", params.stop);
        cy.trigger("layoutstop");
    };

    BreadthFirstLayout.prototype.stop = function(){
        // not a continuous layout
    };

    $$("layout", "breadthfirst", BreadthFirstLayout);

})( cytoscape );

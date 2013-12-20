/*
   Some cystoscape functions are overiden here, in order to:
   - Fix bugs
   - Change the default behavior which can not do through api or configuration
 */

(function($$){

    $$("layout", "breadthfirst").prototype.run = function(){
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

    var canvas_prototype = $$("renderer", "canvas").prototype;
    var CANVAS_LAYERS = 5, SELECT_BOX = 0, DRAG = 2, OVERLAY = 3, NODE = 4, BUFFER_COUNT = 2;

    // Change the dault value for SEEK, it looks better with 6 instead of 10
    canvas_prototype.getRoundRectangleRadius = function(width, height) {
        return Math.min(width / 2, height / 2, 6);
    }

    //Fix for the case that the graph disappears when browser is in the zoom mode
    canvas_prototype.matchCanvasSize = function(container) {
        var data = this.data; var width = container.clientWidth; var height = container.clientHeight;

        var canvas, canvasWidth = width, canvasHeight = height;

        // Comment out these lines to fix that the graph disappears when browser is in the zoom mode
        //if ('devicePixelRatio' in window) {
        //	canvasWidth *= devicePixelRatio;
        //	canvasHeight *= devicePixelRatio;
        //}

        for (var i = 0; i < CANVAS_LAYERS; i++) {

            canvas = data.canvases[i];

            if (canvas.width !== canvasWidth || canvas.height !== canvasHeight) {

                canvas.width = canvasWidth;
                canvas.height = canvasHeight;

                canvas.style.width = width + 'px';
                canvas.style.height = height + 'px';
            }
        }

        for (var i = 0; i < BUFFER_COUNT; i++) {

            canvas = data.bufferCanvases[i];

            if (canvas.width !== canvasWidth || canvas.height !== canvasHeight) {

                canvas.width = canvasWidth;
                canvas.height = canvasHeight;
            }
        }

        this.data.overlay.style.width = width + 'px';
        this.data.overlay.style.height = height + 'px';
    }

    // Fix the safari 6.1 and above quits unexpectedly
    canvas_prototype.roundRectangleIntersectLine = function(
        x, y, nodeX, nodeY, width, height, padding) {

        //Manually change for seek to fix that safari quits unexpectedly
        var cornerRadius = 0;

        var halfWidth = width / 2;
        var halfHeight = height / 2;

        // Check intersections with straight line segments
        var straightLineIntersections;

        // Top segment, left to right
        {
            var topStartX = nodeX - halfWidth + cornerRadius - padding;
            var topStartY = nodeY - halfHeight - padding;
            var topEndX = nodeX + halfWidth - cornerRadius + padding;
            var topEndY = topStartY;

            straightLineIntersections = this.finiteLinesIntersect(
                x, y, nodeX, nodeY, topStartX, topStartY, topEndX, topEndY, false);

            if (straightLineIntersections.length > 0) {
                return straightLineIntersections;
            }
        }

        // Right segment, top to bottom
        {
            var rightStartX = nodeX + halfWidth + padding;
            var rightStartY = nodeY - halfHeight + cornerRadius - padding;
            var rightEndX = rightStartX;
            var rightEndY = nodeY + halfHeight - cornerRadius + padding;

            straightLineIntersections = this.finiteLinesIntersect(
                x, y, nodeX, nodeY, rightStartX, rightStartY, rightEndX, rightEndY, false);

            if (straightLineIntersections.length > 0) {
                return straightLineIntersections;
            }
        }

        // Bottom segment, left to right
        {
            var bottomStartX = nodeX - halfWidth + cornerRadius - padding;
            var bottomStartY = nodeY + halfHeight + padding;
            var bottomEndX = nodeX + halfWidth - cornerRadius + padding;
            var bottomEndY = bottomStartY;

            straightLineIntersections = this.finiteLinesIntersect(
                x, y, nodeX, nodeY, bottomStartX, bottomStartY, bottomEndX, bottomEndY, false);

            if (straightLineIntersections.length > 0) {
                return straightLineIntersections;
            }
        }

        // Left segment, top to bottom
        {
            var leftStartX = nodeX - halfWidth - padding;
            var leftStartY = nodeY - halfHeight + cornerRadius - padding;
            var leftEndX = leftStartX;
            var leftEndY = nodeY + halfHeight - cornerRadius + padding;

            straightLineIntersections = this.finiteLinesIntersect(
                x, y, nodeX, nodeY, leftStartX, leftStartY, leftEndX, leftEndY, false);

            if (straightLineIntersections.length > 0) {
                return straightLineIntersections;
            }
        }

        // Check intersections with arc segments
        var arcIntersections;

        // Top Left
        {
            var topLeftCenterX = nodeX - halfWidth + cornerRadius;
            var topLeftCenterY = nodeY - halfHeight + cornerRadius
            arcIntersections = this.intersectLineCircle(
                x, y, nodeX, nodeY,
                topLeftCenterX, topLeftCenterY, cornerRadius + padding);

            // Ensure the intersection is on the desired quarter of the circle
            if (arcIntersections.length > 0
                && arcIntersections[0] <= topLeftCenterX
                && arcIntersections[1] <= topLeftCenterY) {
                return [arcIntersections[0], arcIntersections[1]];
            }
        }

        // Top Right
        {
            var topRightCenterX = nodeX + halfWidth - cornerRadius;
            var topRightCenterY = nodeY - halfHeight + cornerRadius
            arcIntersections = this.intersectLineCircle(
                x, y, nodeX, nodeY,
                topRightCenterX, topRightCenterY, cornerRadius + padding);

            // Ensure the intersection is on the desired quarter of the circle
            if (arcIntersections.length > 0
                && arcIntersections[0] >= topRightCenterX
                && arcIntersections[1] <= topRightCenterY) {
                return [arcIntersections[0], arcIntersections[1]];
            }
        }

        // Bottom Right
        {
            var bottomRightCenterX = nodeX + halfWidth - cornerRadius;
            var bottomRightCenterY = nodeY + halfHeight - cornerRadius
            arcIntersections = this.intersectLineCircle(
                x, y, nodeX, nodeY,
                bottomRightCenterX, bottomRightCenterY, cornerRadius + padding);

            // Ensure the intersection is on the desired quarter of the circle
            if (arcIntersections.length > 0
                && arcIntersections[0] >= bottomRightCenterX
                && arcIntersections[1] >= bottomRightCenterY) {
                return [arcIntersections[0], arcIntersections[1]];
            }
        }

        // Bottom Left
        {
            var bottomLeftCenterX = nodeX - halfWidth + cornerRadius;
            var bottomLeftCenterY = nodeY + halfHeight - cornerRadius
            arcIntersections = this.intersectLineCircle(
                x, y, nodeX, nodeY,
                bottomLeftCenterX, bottomLeftCenterY, cornerRadius + padding);

            // Ensure the intersection is on the desired quarter of the circle
            if (arcIntersections.length > 0
                && arcIntersections[0] <= bottomLeftCenterX
                && arcIntersections[1] >= bottomLeftCenterY) {
                return [arcIntersections[0], arcIntersections[1]];
            }
        }
    }

    // Fix the safari 6.1 and above quits unexpectedly
    canvas_prototype.redraw = function( forcedContext, drawAll, forcedZoom, forcedPan ) {
        var r = this;

        if( this.averageRedrawTime === undefined ){ this.averageRedrawTime = 0; }

        var minRedrawLimit = 1000/60; // people can't see much better than 60fps
        var maxRedrawLimit = 1000; // don't cap max b/c it's more important to be responsive than smooth

        var redrawLimit = this.averageRedrawTime; // estimate the ideal redraw limit based on how fast we can draw

        redrawLimit = Math.max(minRedrawLimit, redrawLimit);
        redrawLimit = Math.min(redrawLimit, maxRedrawLimit);

        //console.log('--\nideal: %i; effective: %i', this.averageRedrawTime, redrawLimit);

        if( this.lastDrawTime === undefined ){ this.lastDrawTime = 0; }

        var nowTime = +new Date;
        var timeElapsed = nowTime - this.lastDrawTime;
        var callAfterLimit = timeElapsed >= redrawLimit;

        if( !forcedContext ){
            if( !callAfterLimit ){
                clearTimeout( this.redrawTimeout );
                this.redrawTimeout = setTimeout(function(){
                    r.redraw();
                }, redrawLimit);

                return;
            }

            this.lastDrawTime = nowTime;
        }


        // start on thread ready
        setTimeout(function(){

            var startTime = nowTime;

            var looperMax = 100;
            //console.log('-- redraw --')

            // console.time('init'); for( var looper = 0; looper <= looperMax; looper++ ){

            var cy = r.data.cy; var data = r.data;
            var nodes = r.getCachedNodes(); var edges = r.getCachedEdges();
            r.matchCanvasSize(data.container);

            var zoom = cy.zoom();
            var effectiveZoom = forcedZoom !== undefined ? forcedZoom : zoom;
            var pan = cy.pan();
            var effectivePan = {
                x: pan.x,
                y: pan.y
            };

            if( forcedPan ){
                effectivePan = forcedPan;
            }

            // Comment out these lines to fix that the graph disappears when browser is in the zoom mode
            //if( 'devicePixelRatio' in window ){
            //	effectiveZoom *= devicePixelRatio;
            //	effectivePan.x *= devicePixelRatio;
            //	effectivePan.y *= devicePixelRatio;
            //}

            var elements = [];
            for( var i = 0; i < nodes.length; i++ ){
                elements.push( nodes[i] );
            }
            for( var i = 0; i < edges.length; i++ ){
                elements.push( edges[i] );
            }

            // } console.timeEnd('init')



            if (data.canvasNeedsRedraw[DRAG] || data.canvasNeedsRedraw[NODE] || drawAll) {
                //NB : VERY EXPENSIVE
                //console.time('edgectlpts'); for( var looper = 0; looper <= looperMax; looper++ ){

                if( r.hideEdgesOnViewport && (r.pinching || r.hoverData.dragging || r.data.wheel || r.swipePanning) ){
                } else {
                    r.findEdgeControlPoints(edges);
                }

                //} console.timeEnd('edgectlpts')



                // console.time('sort'); for( var looper = 0; looper <= looperMax; looper++ ){
                var elements = r.getCachedZSortedEles();
                // } console.timeEnd('sort')

                // console.time('updatecompounds'); for( var looper = 0; looper <= looperMax; looper++ ){
                // no need to update graph if there is no compound node
                if ( cy.hasCompoundNodes() )
                {
                    r.updateAllCompounds(elements);
                }
                // } console.timeEnd('updatecompounds')
            }

            var elesInDragLayer;
            var elesNotInDragLayer;
            var element;


            // console.time('drawing'); for( var looper = 0; looper <= looperMax; looper++ ){
            if (data.canvasNeedsRedraw[NODE] || drawAll) {
                // console.log("redrawing node layer", data.canvasRedrawReason[NODE]);

                if( !elesInDragLayer || !elesNotInDragLayer ){
                    elesInDragLayer = [];
                    elesNotInDragLayer = [];

                    for (var index = 0; index < elements.length; index++) {
                        element = elements[index];

                        if ( element._private.rscratch.inDragLayer ) {
                            elesInDragLayer.push( element );
                        } else {
                            elesNotInDragLayer.push( element );
                        }
                    }
                }

                var context = forcedContext || data.canvases[NODE].getContext("2d");

                context.setTransform(1, 0, 0, 1, 0, 0);
                context.clearRect(0, 0, context.canvas.width, context.canvas.height);

                if( !drawAll ){
                    context.translate(effectivePan.x, effectivePan.y);
                    context.scale(effectiveZoom, effectiveZoom);
                }
                if( forcedPan ){
                    context.translate(forcedPan.x, forcedPan.y);
                }
                if( forcedZoom ){
                    context.scale(forcedZoom, forcedZoom);
                }

                for (var index = 0; index < elesNotInDragLayer.length; index++) {
                    element = elesNotInDragLayer[index];

                    if (element._private.group == "nodes") {
                        r.drawNode(context, element);

                    } else if (element._private.group == "edges") {
                        r.drawEdge(context, element);
                    }
                }

                for (var index = 0; index < elesNotInDragLayer.length; index++) {
                    element = elesNotInDragLayer[index];

                    if (element._private.group == "nodes") {
                        r.drawNodeText(context, element);
                    } else if (element._private.group == "edges") {
                        r.drawEdgeText(context, element);
                    }

                    // draw the overlay
                    if (element._private.group == "nodes") {
                        r.drawNode(context, element, true);
                    } else if (element._private.group == "edges") {
                        r.drawEdge(context, element, true);
                    }
                }

                if( !drawAll ){
                    data.canvasNeedsRedraw[NODE] = false; data.canvasRedrawReason[NODE] = [];
                }
            }

            if (data.canvasNeedsRedraw[DRAG] || drawAll) {
                // console.log("redrawing drag layer", data.canvasRedrawReason[DRAG]);

                if( !elesInDragLayer || !elesNotInDragLayer ){
                    elesInDragLayer = [];
                    elesNotInDragLayer = [];

                    for (var index = 0; index < elements.length; index++) {
                        element = elements[index];

                        if ( element._private.rscratch.inDragLayer ) {
                            elesInDragLayer.push( element );
                        } else {
                            elesNotInDragLayer.push( element );
                        }
                    }
                }

                var context = forcedContext || data.canvases[DRAG].getContext("2d");

                if( !drawAll ){
                    context.setTransform(1, 0, 0, 1, 0, 0);
                    context.clearRect(0, 0, context.canvas.width, context.canvas.height);

                    context.translate(effectivePan.x, effectivePan.y);
                    context.scale(effectiveZoom, effectiveZoom);
                }
                if( forcedPan ){
                    context.translate(forcedPan.x, forcedPan.y);
                }
                if( forcedZoom ){
                    context.scale(forcedZoom, forcedZoom);
                }

                var element;

                for (var index = 0; index < elesInDragLayer.length; index++) {
                    element = elesInDragLayer[index];

                    if (element._private.group == "nodes") {
                        r.drawNode(context, element);
                    } else if (element._private.group == "edges") {
                        r.drawEdge(context, element);
                    }
                }

                for (var index = 0; index < elesInDragLayer.length; index++) {
                    element = elesInDragLayer[index];

                    if (element._private.group == "nodes") {
                        r.drawNodeText(context, element);
                    } else if (element._private.group == "edges") {
                        r.drawEdgeText(context, element);
                    }

                    // draw the overlay
                    if (element._private.group == "nodes") {
                        r.drawNode(context, element, true);
                    } else if (element._private.group == "edges") {
                        r.drawEdge(context, element, true);
                    }
                }

                if( !drawAll ){
                    data.canvasNeedsRedraw[DRAG] = false; data.canvasRedrawReason[DRAG] = [];
                }
            }

            if (data.canvasNeedsRedraw[SELECT_BOX]) {
                // console.log("redrawing selection box", data.canvasRedrawReason[SELECT_BOX]);

                var context = forcedContext || data.canvases[SELECT_BOX].getContext("2d");

                if( !drawAll ){
                    context.setTransform(1, 0, 0, 1, 0, 0);
                    context.clearRect(0, 0, context.canvas.width, context.canvas.height);

                    context.translate(effectivePan.x, effectivePan.y);
                    context.scale(effectiveZoom, effectiveZoom);
                }
                if( forcedPan ){
                    context.translate(forcedPan.x, forcedPan.y);
                }
                if( forcedZoom ){
                    context.scale(forcedZoom, forcedZoom);
                }

                var coreStyle = cy.style()._private.coreStyle;

                if (data.select[4] == 1) {
                    var zoom = data.cy.zoom();
                    var borderWidth = coreStyle["selection-box-border-width"].value / zoom;

                    context.lineWidth = borderWidth;
                    context.fillStyle = "rgba("
                        + coreStyle["selection-box-color"].value[0] + ","
                        + coreStyle["selection-box-color"].value[1] + ","
                        + coreStyle["selection-box-color"].value[2] + ","
                        + coreStyle["selection-box-opacity"].value + ")";

                    context.fillRect(
                        data.select[0],
                        data.select[1],
                        data.select[2] - data.select[0],
                        data.select[3] - data.select[1]);

                    if (borderWidth > 0) {
                        context.strokeStyle = "rgba("
                            + coreStyle["selection-box-border-color"].value[0] + ","
                            + coreStyle["selection-box-border-color"].value[1] + ","
                            + coreStyle["selection-box-border-color"].value[2] + ","
                            + coreStyle["selection-box-opacity"].value + ")";

                        context.strokeRect(
                            data.select[0],
                            data.select[1],
                            data.select[2] - data.select[0],
                            data.select[3] - data.select[1]);
                    }
                }

                if( data.bgActivePosistion ){
                    var zoom = data.cy.zoom();
                    var pos = data.bgActivePosistion;

                    context.fillStyle = "rgba("
                        + coreStyle["active-bg-color"].value[0] + ","
                        + coreStyle["active-bg-color"].value[1] + ","
                        + coreStyle["active-bg-color"].value[2] + ","
                        + coreStyle["active-bg-opacity"].value + ")";

                    context.beginPath();
                    context.arc(pos.x, pos.y, coreStyle["active-bg-size"].pxValue / zoom, 0, 2 * Math.PI);
                    context.fill();
                }

                if( !drawAll ){
                    data.canvasNeedsRedraw[SELECT_BOX] = false; data.canvasRedrawReason[SELECT_BOX] = [];
                }
            }

            if( r.options.showOverlay ){
                var context = data.canvases[OVERLAY].getContext("2d");

                context.lineJoin = 'round';
                context.font = '14px helvetica';
                context.strokeStyle = '#fff';
                context.lineWidth = '4';
                context.fillStyle = '#666';
                context.textAlign = 'right';

                var text = 'cytoscape.js';

                var w = context.canvas.width;
                var h = context.canvas.height;
                var p = 4;
                var tw = context.measureText(text).width;
                var th = 14;

                context.clearRect(0, 0, w, h);
                context.strokeText(text, w - p, h - p);
                context.fillText(text, w - p, h - p);

                data.overlayDrawn = true;
            }

            // } console.timeEnd('drawing')

            var endTime = +new Date;

            if( r.averageRedrawTime === undefined ){
                r.averageRedrawTime = endTime - startTime;
            }

            // use a weighted average with a bias from the previous average so we don't spike so easily
            r.averageRedrawTime = r.averageRedrawTime/2 + (endTime - startTime)/2;
            //console.log('actual: %i, average: %i', endTime - startTime, this.averageRedrawTime);


            // end on thread ready
        }, 0);
    };
})( cytoscape );


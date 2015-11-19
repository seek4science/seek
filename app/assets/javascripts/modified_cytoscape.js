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


    function wrapText(context, text, x, y, maxWidth, lineHeight) {
        var words = text.split(' ');
        var line = '';

        for (var n = 0; n < words.length; n++) {
            var testLine = line + words[n] + ' ';
            var metrics = context.measureText(testLine);
            var testWidth = metrics.width;
            testWidth = testWidth / ((lineHeight - 1) / 7);
            if (testWidth > maxWidth && n > 0) {
                context.fillText(line, x, y);
                line = words[n] + ' ';
                y += lineHeight;
            }
            else {
                line = testLine;
            }
        }

        context.fillText(line, x, y);
    }

    canvas_prototype.calculateLabelDimensions = function( ele, text, extraKey ){
        var r = this;
        var style = ele._private.style;
        var fStyle = style['font-style'].strValue;
        var size = style['font-size'].pxValue + 'px';
        var family = style['font-family'].strValue;
        // var variant = style['font-variant'].strValue;
        var weight = style['font-weight'].strValue;

        var cacheKey = ele._private.labelKey;

        if( extraKey ){
            cacheKey += '$@$' + extraKey;
        }

        var cache = r.labelDimCache || (r.labelDimCache = {});

        if( cache[cacheKey] ){
            return cache[cacheKey];
        }

        var div = this.labelCalcDiv;

        if( !div ){
            div = this.labelCalcDiv = document.createElement('div');
            document.body.appendChild( div );
        }

        var ds = div.style;

        // from ele style
        ds.fontFamily = family;
        ds.fontStyle = fStyle;
        ds.fontSize = size;
        // ds.fontVariant = variant;
        ds.fontWeight = weight;

        // forced style
        ds.position = 'absolute';
        ds.left = '-9999px';
        ds.top = '-9999px';
        ds.zIndex = '-1';
        ds.visibility = 'hidden';
        ds.pointerEvents = 'none';
        ds.padding = '0';
        ds.lineHeight = '1';

        if( style['text-wrap'].value === 'wrap' ){
            ds.whiteSpace = 'pre'; // so newlines are taken into account
        } else {
            ds.whiteSpace = 'normal';
        }

        // put label content in div
        div.textContent = text;

        cache[cacheKey] = {
            width: div.clientWidth,
            height: div.clientHeight
        };

        return cache[cacheKey];
    };


    canvas_prototype.getLabelText = function( ele ){
        var style = ele._private.style;
        var text = ele._private.style['content'].strValue;
        var textTransform = style['text-transform'].value;
        var rscratch = ele._private.rscratch;

        if (textTransform == 'none') {
        } else if (textTransform == 'uppercase') {
            text = text.toUpperCase();
        } else if (textTransform == 'lowercase') {
            text = text.toLowerCase();
        }

        if(ele.isNode() && style['text-wrap'].value === 'wrap' ){
            //console.log('wrap');

            // save recalc if the label is the same as before
            if( ele._private.labelWrapKey === ele._private.labelKey && ele._private.labelKey != null ){
                // console.log('wrap cache hit');
                return ele._private.labelWrapCachedText;
            }
            // console.log('wrap cache miss');

            var lines = text.split('\n');
            var maxW = style['text-max-width'].pxValue;
            var wrappedLines = [];

            for( var l = 0; l < lines.length; l++ ){
                var line = lines[l];
                var lineDims = this.calculateLabelDimensions( ele, line, 'line=' + line );
                var lineW = lineDims.width;

                if( lineW > maxW ){ // line is too long
                    var words = line.split(/\s+/); // NB: assume collapsed whitespace into single space
                    var subline = '';

                    for( var w = 0; w < words.length; w++ ){
                        var word = words[w];
                        var testLine = subline.length === 0 ? word : subline + ' ' + word;
                        var testDims = this.calculateLabelDimensions( ele, testLine, 'testLine=' + testLine );
                        var testW = testDims.width;

                        if( testW <= maxW ){ // word fits on current line
                            subline += word + ' ';
                        } else { // word starts new line
                            wrappedLines.push( subline );
                            subline = word + ' ';
                        }
                    }

                    // if there's remaining text, put it in a wrapped line
                    if( !subline.match(/^\s+$/) ){
                        wrappedLines.push( subline );
                    }
                } else { // line is already short enough
                    wrappedLines.push( line );
                }
            } // for

            ele._private.labelWrapCachedLines = wrappedLines;
            ele._private.labelWrapCachedText = text = wrappedLines.join('\n');
            ele._private.labelWrapKey = ele._private.labelKey;

            // console.log(text)
        } // if wrap

        return text;
    };

    // Draw text
    canvas_prototype.drawText = function(context, element, textX, textY) {

        var parentOpacity = 1;
        var parents = element.parents();
        for( var i = 0; i < parents.length; i++ ){
            var parent = parents[i];
            var opacity = parent._private.style.opacity.value;

            parentOpacity = opacity * parentOpacity;

            if( opacity === 0 ){
                return;
            }
        }

        // Font style
        var labelStyle = element._private.style["font-style"].strValue;
        var labelSize = element._private.style["font-size"].value + "px";
        var labelFamily = element._private.style["font-family"].strValue;
        var labelVariant = element._private.style["font-variant"].strValue;
        var labelWeight = element._private.style["font-weight"].strValue;

        context.font = labelStyle + " " + labelWeight + " "
            + labelSize + " " + labelFamily;

        //var text = String(element._private.style["content"].value);

        var text = this.getLabelText( element );

        // Calculate text draw position based on text alignment

        // so text outlines aren't jagged
        context.lineJoin = 'round';

        context.fillStyle = "rgba("
            + element._private.style["color"].value[0] + ","
            + element._private.style["color"].value[1] + ","
            + element._private.style["color"].value[2] + ","
            + (element._private.style["text-opacity"].value
            * element._private.style["opacity"].value * parentOpacity) + ")";

        context.strokeStyle = "rgba("
            + element._private.style["text-outline-color"].value[0] + ","
            + element._private.style["text-outline-color"].value[1] + ","
            + element._private.style["text-outline-color"].value[2] + ","
            + (element._private.style["text-opacity"].value
            * element._private.style["opacity"].value * parentOpacity) + ")";

        if (text != undefined) {
            var lineWidth = 2  * element._private.style["text-outline-width"].value; // *2 b/c the stroke is drawn centred on the middle
            if (lineWidth > 0) {
                context.lineWidth = lineWidth;
                //context.strokeText(text, textX, textY);
            }

            // Thanks sysord@github for the isNaN checks!
            if (isNaN(textX)) { textX = 0; }
            if (isNaN(textY)) { textY = 0; }

            //context.fillText("" + text, textX, textY);
            var style = element._private.style;
            var halign = style['text-halign'].value;
            var valign = style['text-valign'].value;

            var rstyle = element._private.rstyle;
            var rscratch = element._private.rscratch;
            if( element.isNode() && style['text-wrap'].value === 'wrap' ){ //console.log('draw wrap');
                var lines = element._private.labelWrapCachedLines;
                //var lineHeight = rstyle.labelHeight / lines.length;
                var lineHeight = style['font-size'].value + 1;

                //console.log('lines', lines);

                switch( valign ){
                    case 'top':
                        textY -= (lines.length - 1) * lineHeight;
                        break;

                    case 'bottom':
                        // nothing required
                        break;

                    default:
                    case 'center':
                        textY -= (lines.length - 1) * lineHeight / 2;
                }

                for( var l = 0; l < lines.length; l++ ){
                    if( lineWidth > 0 ){
                        context.strokeText( lines[l], textX, textY );
                    }

                    context.fillText( lines[l], textX, textY );

                    textY += lineHeight;
                }

                // var fontSize = style['font-size'].pxValue;
                // wrapText(context, text, textX, textY, style['text-max-width'].pxValue, fontSize + 1);
            } else {
                if( lineWidth > 0 ){
                    context.strokeText(text, textX, textY);
                }

                if (element.isNode() && style['text-wrap'].value == 'wrap') {
                    var fontSize = style['font-size'].pxValue;
                    wrapText(context, text, textX, textY, style['text-max-width'].value, fontSize + 1);
                } else {
                    context.fillText(text, textX, textY);
                }
            }

            // record the text's width for use in bounding box calc
            element._private.rstyle.labelWidth = context.measureText( text ).width;
        }
    };

    (function(){
        var number = $$.util.regex.number;
        var rgba = $$.util.regex.rgbaNoBackRefs;
        var hsla = $$.util.regex.hslaNoBackRefs;
        var hex3 = $$.util.regex.hex3;
        var hex6 = $$.util.regex.hex6;

        // each visual style property has a type and needs to be validated according to it
        $$.style.types = {
            zeroOneNumber: { number: true, min: 0, max: 1, unitless: true },
            nonNegativeInt: { number: true, min: 0, integer: true, unitless: true },
            size: { number: true, min: 0, enums: ["auto"] },
            bgSize: { number: true, min: 0, allowPercent: true },
            color: { color: true },
            lineStyle: { enums: ["solid", "dotted", "dashed"] },
            curveStyle: { enums: ["bundled", "bezier"] },
            fontFamily: { regex: "^([\\w- ]+(?:\\s*,\\s*[\\w- ]+)*)$" },
            fontVariant: { enums: ["small-caps", "normal"] },
            fontStyle: { enums: ["italic", "normal", "oblique"] },
            fontWeight: { enums: ["normal", "bold", "bolder", "lighter", "100", "200", "300", "400", "500", "600", "800", "900", 100, 200, 300, 400, 500, 600, 700, 800, 900] },
            textDecoration: { enums: ["none", "underline", "overline", "line-through"] },
            textTransform: { enums: ["none", "capitalize", "uppercase", "lowercase"] },
            nodeShape: { enums: ["rectangle", "roundrectangle", "ellipse", "triangle",
                "square", "pentagon", "hexagon", "heptagon", "octagon"] },
            arrowShape: { enums: ["tee", "triangle", "square", "circle", "diamond", "none"] },
            visibility: { enums: ["hidden", "visible"] },
            valign: { enums: ["top", "center", "bottom"] },
            halign: { enums: ["left", "center", "right"] },
            positionx: { enums: ["left", "center", "right"], number: true, allowPercent: true },
            positiony: { enums: ["top", "center", "bottom"], number: true, allowPercent: true },
            bgRepeat: { enums: ["repeat", "repeat-x", "repeat-y", "no-repeat"] },
            cursor: { enums: ["auto", "crosshair", "default", "e-resize", "n-resize", "ne-resize", "nw-resize", "pointer", "progress", "s-resize", "sw-resize", "text", "w-resize", "wait", "grab", "grabbing"] },
            text: { string: true },
            data: { mapping: true, regex: "^data\\s*\\(\\s*([\\w\\.]+)\\s*\\)$" },
            mapData: { mapping: true, regex: "^mapData\\(([\\w\\.]+)\\s*\\,\\s*(" + number + ")\\s*\\,\\s*(" + number + ")\\s*,\\s*(" + number + "|\\w+|" + rgba + "|" + hsla + "|" + hex3 + "|" + hex6 + ")\\s*\\,\\s*(" + number + "|\\w+|" + rgba + "|" + hsla + "|" + hex3 + "|" + hex6 + ")\\)$" },
            url: { regex: "^url\\s*\\(\\s*([^\\s]+)\\s*\\s*\\)|none|(.+)$" },
            textWrap: { enums: ['none', 'wrap'] }
        };

        // define visual style properties
        var t = $$.style.types;
        $$.style.properties = [
            // these are for elements
            { name: "cursor", type: t.cursor },
            { name: "text-valign", type: t.valign },
            { name: "text-halign", type: t.halign },
            { name: "color", type: t.color },
            { name: "content", type: t.text },
            { name: "text-outline-color", type: t.color },
            { name: "text-outline-width", type: t.size },
            { name: "text-outline-opacity", type: t.zeroOneNumber },
            { name: "text-opacity", type: t.zeroOneNumber },
            { name: "text-decoration", type: t.textDecoration },
            { name: "text-transform", type: t.textTransform },
            { name: "font-family", type: t.fontFamily },
            { name: "font-style", type: t.fontStyle },
            { name: "font-variant", type: t.fontVariant },
            { name: "font-weight", type: t.fontWeight },
            { name: "font-size", type: t.size },
            { name: "min-zoomed-font-size", type: t.size },
            { name: "visibility", type: t.visibility },
            { name: "opacity", type: t.zeroOneNumber },
            { name: "z-index", type: t.nonNegativeInt },
            { name: "overlay-padding", type: t.size },
            { name: "overlay-color", type: t.color },
            { name: "overlay-opacity", type: t.zeroOneNumber },
            { name: 'text-wrap', type: t.textWrap },
            { name: 'text-max-width', type: t.size },

            // these are just for nodes
            { name: "background-color", type: t.color },
            { name: "background-opacity", type: t.zeroOneNumber },
            { name: "background-image", type: t.url },
            { name: "background-position-x", type: t.positionx },
            { name: "background-position-y", type: t.positiony },
            { name: "background-repeat", type: t.bgRepeat },
            { name: "background-size-x", type: t.bgSize },
            { name: "background-size-y", type: t.bgSize },
            { name: "border-color", type: t.color },
            { name: "border-opacity", type: t.zeroOneNumber },
            { name: "border-width", type: t.size },
            { name: "border-style", type: t.lineStyle },
            { name: "height", type: t.size },
            { name: "width", type: t.size },
            { name: "padding-left", type: t.size },
            { name: "padding-right", type: t.size },
            { name: "padding-top", type: t.size },
            { name: "padding-bottom", type: t.size },
            { name: "shape", type: t.nodeShape },

            // these are just for edges
            { name: "source-arrow-shape", type: t.arrowShape },
            { name: "target-arrow-shape", type: t.arrowShape },
            { name: "source-arrow-color", type: t.color },
            { name: "target-arrow-color", type: t.color },
            { name: "line-style", type: t.lineStyle },
            { name: "line-color", type: t.color },
            { name: "control-point-step-size", type: t.size },
            { name: "curve-style", type: t.curveStyle },

            // these are just for the core
            { name: "selection-box-color", type: t.color },
            { name: "selection-box-opacity", type: t.zeroOneNumber },
            { name: "selection-box-border-color", type: t.color },
            { name: "selection-box-border-width", type: t.size },
            { name: "panning-cursor", type: t.cursor },
            { name: "active-bg-color", type: t.color },
            { name: "active-bg-opacity", type: t.zeroOneNumber },
            { name: "active-bg-size", type: t.size }
        ];

        // allow access of properties by name ( e.g. $$.style.properties.height )
        var props = $$.style.properties;
        for( var i = 0; i < props.length; i++ ){
            var prop = props[i];

            props[ prop.name ] = prop; // allow lookup by name
        }
    })();


    $$.styfn.updateStyleHints = function(ele){
        if (ele !== undefined && ele.isNode()) {
            var _p = ele._private;
            var self = this;
            var style = _p.style;

            // set whether has pie or not; for greater efficiency
            var hasPie = false;
            if (_p.group === 'nodes' && self._private.hasPie) {
                for (var i = 1; i <= $$.style.pieBackgroundN; i++) { // 1..N
                    var size = _p.style['pie-' + i + '-background-size'].value;

                    if (size > 0) {
                        hasPie = true;
                        break;
                    }
                }
            }

            _p.hasPie = hasPie;

            var transform = style['text-transform'].strValue;
            var content = style['content'].strValue;
            var fStyle = style['font-style'].strValue;
            var size = style['font-size'].pxValue + 'px';
            var family = style['font-family'].strValue;
            // var variant = style['font-variant'].strValue;
            var weight = style['font-weight'].strValue;
            var valign = style['text-valign'].strValue;
            var halign = style['text-valign'].strValue;
            var oWidth = style['text-outline-width'].pxValue;
            var wrap = style['text-wrap'].strValue;
            var wrapW = style['text-max-width'].pxValue;
            _p.labelKey = fStyle + '$' + size + '$' + family + '$' + weight + '$' + content + '$' + transform + '$' + valign + '$' + halign + '$' + oWidth + '$' + wrap + '$' + wrapW;
            _p.fontKey = fStyle + '$' + weight + '$' + size + '$' + family;

            var width = style['width'].pxValue;
            var height = style['height'].pxValue;
            var borderW = style['border-width'].pxValue;
            _p.boundingBoxKey = width + '$' + height + '$' + borderW;

            if (ele._private.group === 'edges') {
                var cpss = style['control-point-step-size'].pxValue;
                var cpd = style['control-point-distance'] ? style['control-point-distance'].pxValue : undefined;
                var cpw = style['control-point-weight'].value;
                var curve = style['curve-style'].strValue;

                _p.boundingBoxKey += '$' + cpss + '$' + cpd + '$' + cpw + '$' + curve;
            }

            _p.styleKey = Date.now(); // probably safe to use applied time and much faster
            // for( var i = 0; i < $$.style.properties.length; i++ ){
            //   var prop = $$.style.properties[i];
            //   var eleProp = _p.style[ prop.name ];
            //   var val = eleProp && eleProp.strValue ? eleProp.strValue : 'undefined';

            //   _p.styleKey += '$' + val;
            // }
        }
    };


    $$.styfn.apply = function( eles ){
        var self = this;

        for( var ie = 0; ie < eles.length; ie++ ){
            var ele = eles[ie];

            if( self._private.newStyle ){
                ele._private.styleCxts = [];
                ele._private.style = {};
            }

            // apply the styles
            for( var i = 0; i < this.length; i++ ){
                var context = this[i];
                var contextSelectorMatches = context.selector && context.selector.filter( ele ).length > 0; // NB: context.selector may be null for "core"
                var props = context.properties;

                if( contextSelectorMatches ){ // then apply its properties

                    // apply the properties in the context

                    for( var j = 0; j < props.length; j++ ){ // for each prop
                        var prop = props[j];

                        //if(prop.mapped) debugger;

                        if( !ele._private.styleCxts[i] || prop.mapped ){
                            this.applyParsedProperty( ele, prop, context );
                        }
                    }

                    // keep a note that this context matches
                    ele._private.styleCxts[i] = context;
                } else {

                    // roll back style cxts that don't match now
                    if( ele._private.styleCxts[i] ){
                        this.rollBackContext( ele, context );
                    }

                    delete ele._private.styleCxts[i];
                }

            } // for context

        } // for elements

        this.updateStyleHints(ele);

        self._private.newStyle = false;
    };

})( cytoscape );

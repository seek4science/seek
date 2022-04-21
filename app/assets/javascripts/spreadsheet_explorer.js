


$j(document).ready(function ($j) {

    //Auto scrolling
    var xInc = "+=0";
    var yInc = "+=0";
    var slowScrollBoundary = 100; //Distance from the edge of the spreadsheet in pixels at which automatic scrolling starts when dragging out a selection
    var fastScrollBoundary = 50; //As above, but faster scrolling
    var scrolling = false;

    //Cell selection
    var isMouseDown = false,
        startRow,
        startCol,
        endRow,
        endCol;

    //To disable text-selection
    //http://stackoverflow.com/questions/2700000/how-to-disable-text-selection-using-jquery
    $j.fn.disableSelect = function() {
        $j(this).attr('unselectable', 'on')
            .css('-moz-user-select', 'none')
            .each(function() {
                this.onselectstart = function() { return false; };
            });
    };

    //Clickable worksheet tabs
    $j("a.sheet_tab")
        .click(function () {
            activateSheet(null, $j(this));
        })
        .mouseover(function (){
            this.style.cursor = 'pointer';
        });

    //Cell selection
    $j("table.sheet td.cell")
        .mousedown(function () {
            //enable selection of cells only in spreadsheet explore, not search preview.
            if ($j('div#spreadsheet_outer_frame').length > 0) {
                if (!isMouseDown) {
                    //Update the cell info box to contain either the value of the cell or the formula
                    // also make hovering over the info box display all the text.
                    if ($j(this).attr("title")) {
                        $j('#cell_value').text($j(this).attr("title"));
                        $j('#cell_value').attr("title", $j(this).attr("title"));
                    }
                    else {
                        $j('#cell_value').text($j(this).html());
                        $j('#cell_value').attr("title", $j(this).html());
                    }
                    isMouseDown = true;
                    startRow = parseInt($j(this).attr("row"));
                    startCol = parseInt($j(this).attr("col"));
                }

                select_cells(startCol, startRow, startCol, startRow, null);

                return false; // prevent text selection
            }
        })
        .mouseover(function (e) {
            if (isMouseDown) {

                endRow = parseInt($j(this).attr("row"));
                endCol = parseInt($j(this).attr("col"));

                select_cells(startCol, startRow, endCol, endRow, null);
            }
        })
    ;

    //Auto scrolling when selection box is dragged to the edge of the view
    $j("div.sheet")
        .mousemove(function (e) {
            if(isMouseDown)
            {
                var sheet = $j("div.active_sheet");
                if(e.pageY >= (sheet.position().top + sheet.outerHeight()) - slowScrollBoundary)
                    if(e.pageY >= (sheet.position().top + sheet.outerHeight()) - fastScrollBoundary)
                        yInc =  "+=50px";
                    else
                        yInc =  "+=10px";
                else if (e.pageY <= (sheet.position().top + slowScrollBoundary))
                    if (e.pageY <= (sheet.position().top + fastScrollBoundary))
                        yInc = "-=50px";
                    else
                        yInc = "-=10px";
                else
                    yInc = "+=0";

                if(e.pageX >= (sheet.position().left + sheet.outerWidth()) - slowScrollBoundary)
                    if(e.pageX >= (sheet.position().left + sheet.outerWidth()) - fastScrollBoundary)
                        xInc =  "+=50px";
                    else
                        xInc =  "+=10px";
                else if (e.pageX <= (sheet.position().left + slowScrollBoundary))
                    if (e.pageX <= (sheet.position().left + fastScrollBoundary))
                        xInc = "-=50px";
                    else
                        xInc = "-=10px";
                else
                    xInc = "+=0";

                if(xInc == "+=0" && yInc == "+=0")
                {
                    scrolling = false;
                }
                else if (!scrolling)
                {
                    sheet.stop();
                    scrolling = true;
                    scroll(sheet);
                }
            }
        })
    ;

    //Scroll headings when sheet is scrolled
    $j("div.sheet")
        .scroll(function (e) {
            $j(this).parent().find("div.row_headings").scrollTop(($j(this)).scrollTop());
            $j(this).parent().parent().find("div.col_headings").scrollLeft(($j(this)).scrollLeft());
        })
    ;

    //http://stackoverflow.com/questions/1511529/how-to-scroll-div-continuously-on-mousedown-event
    function scroll(object) {
        if(!scrolling)
            object.stop();
        else
        {
            object.animate({scrollTop : yInc, scrollLeft : xInc}, 100, function(){
                if (scrolling)
                    scroll(object);
            });
        }
    }
    $j(document)
        .mouseup(function () {
            if (isMouseDown)
            {
                isMouseDown = false;
                if(scrolling)
                {
                    scrolling = false;
                    $j('div.active_sheet').stop();
                }
            }
        })
    ;

    //Resizable column/row headings
    //also makes them clickable to select all cells in that row/column
    $j( "div.col_heading" )
        .resizable({
            minWidth: 20,
            handles: 'e',
            stop: function (){
                //when in spreadsheet "explore"
                if ( (window.location.href).indexOf("explore") > -1 ) {
                    $j("table.active_sheet col:eq(" + ($j(this).index() - 1) + ")").width($j(this).width());
                } else {
                    var obj_id = activate_sheet_from_resizable(this);
                    $j("table." + obj_id + ".active_sheet col:eq(" + ($j(this).index() - 1) + ")").width($j(this).width());
                }
            }
        })
        .mousedown(function(){
            //enable selection of cells only in spreadsheet explore, not search preview.
            if ($j('div#spreadsheet_outer_frame').length > 0) {
                var col = $j(this).index();
                var last_row = $j(this).parent().parent().parent().find("div.row_heading").length;
                select_cells(col, 1, col, last_row, null);
            }
        })
    ;
    $j( "div.row_heading" )
        .resizable({
            minHeight: 15,
            handles: 's',
            stop: function (){
                var height = $j(this).height();
                //when in spreadsheet "explore"
                if ( (window.location.href).indexOf("explore") > -1 ) {
                     $j("table.active_sheet tr:eq(" + $j(this).index() + ")").height(height).css('line-height', height - 2 + "px");
                } else {
                    var obj_id = activate_sheet_from_resizable(this);
                    $j("table." + obj_id + ".active_sheet tr:eq(" + $j(this).index() + ")").height(height).css('line-height', height - 2 + "px");
                }
            }
        })
        .mousedown(function(){
            //enable selection of cells only in spreadsheet explore, not search preview.
            if ($j('div#spreadsheet_outer_frame').length > 0) {
                var row = $j(this).index() + 1;
                var last_col = $j(this).parent().parent().parent().find("div.col_heading").length;
                select_cells(1, row, last_col, row, null);
            }
        })
    ;

});

function activate_sheet_from_resizable(div_obj) {
    var obj_id_sheetN = div_obj.parentNode.parentNode.parentNode.id.split('_');
    activateSheet(null, $j($j("a.sheet_tab."+ obj_id_sheetN[1] )[obj_id_sheetN[2]-1] ) );
    return obj_id_sheetN[1];
}
function max_container_width() {
    var max_width = $j(".corner_heading").width();
    $j(".col_heading").each(function() {
        max_width += parseInt($j(this)[0].style.width);
    });
    return max_width;
}

//Convert a numeric column index to an alphabetic one
function num2alpha(col) {
    var result = "";
    col = col-1; //To make it 0 indexed.

    while (col >= 0)
    {
        result = String.fromCharCode((col % 26) + 65) + result;
        col = Math.floor(col/26) - 1;
    }
    return result;
}

//Convert an alphabetic column index to a numeric one
function alpha2num(col) {
    var result = 0;
    for(var i = col.length-1; i >= 0; i--){
        result += Math.pow(26,col.length - (i + 1)) * (col.charCodeAt(i) - 64);
    }
    return result;
}

//Turns an excel-style cell range into an array of coordinates
function explodeCellRange(range) {
    //Split into component parts (top-left cell, bottom-right cell of a rectangle range)
    var array = range.split(":",2);

    //Get a numeric value for the row and column of each component
    var startCol = alpha2num(array[0].replace(/[0-9]+/,""));
    var startRow = parseInt(array[0].replace(/[A-Z]+/,""));
    var endCol;
    var endRow;

    //If only a single cell specified...
    if(array[1] == undefined) {
        endCol = startCol;
        endRow = startRow;
    }
    else {
        endCol = alpha2num(array[1].replace(/[0-9]+/,""));
        endRow = parseInt(array[1].replace(/[A-Z]+/,""));
    }
    return [startCol,startRow,endCol,endRow];
}



//to identify the current page for a specific sheet
function currentPage(sheetNumber){
    var paginateForSheet = $j('#paginate_sheet_' + (sheetNumber))[0];
    if (paginateForSheet != null)
    {
        var current_page = paginateForSheet.getElementsByClassName('current')[0].innerText;
        return Number(current_page);
    }else{
        return null;
    }

}

function select_range(range, sheetNumber) {
    var coords = explodeCellRange(range);
    var startCol = coords[0],
        startRow = coords[1],
        endCol = coords[2],
        endRow = coords[3];

    if(startRow && startCol && endRow && endCol)
        select_cells(startCol, startRow, endCol, endRow, sheetNumber);

    var relative_rows = relativeRows(startRow, endRow, sheetNumber);
    var relativeMinRow = relative_rows[0];
    var relativeMaxRow = relative_rows[1];

    //Scroll to selected cells
    var row = $j("table.active_sheet tr").slice((relativeMinRow-1),relativeMaxRow).first();
    var cell = row.children("td.cell").slice(startCol-1,endCol).first();

    $j('div.active_sheet').scrollTop(row.position().top + $j('div.active_sheet').scrollTop() - 500);
    $j('div.active_sheet').scrollLeft(cell.position().left + $j('div.active_sheet').scrollLeft() - 500);
}


//Select cells in a specified area
function select_cells(startCol, startRow, endCol, endRow, sheetNumber) {
    var minRow = startRow;
    var minCol = startCol;
    var maxRow = endRow;
    var maxCol = endCol;

    //To ensure minRow/minCol is always less than maxRow/maxCol
    // no matter which direction the box is dragged
    if(endRow <= startRow) {
        minRow = endRow;
        maxRow = startRow;
    }
    if(endCol <= startCol) {
        minCol = endCol;
        maxCol = startCol;
    }

    var relative_rows = relativeRows(minRow, maxRow, sheetNumber);
    var relativeMinRow = relative_rows[0];
    var relativeMaxRow = relative_rows[1];

    //Deselect any cells and headings
    $j(".selected_cell").removeClass("selected_cell");
    $j(".selected_heading").removeClass("selected_heading");

    //"Select" dragged cells
    $j("table.active_sheet tr").slice(relativeMinRow-1,relativeMaxRow).each(function() {
        $j(this).children("td.cell:not(.selected_cell)").slice(minCol-1,maxCol).addClass("selected_cell");
    });

    //"Select" dragged cells' column headings
    $j("div.active_sheet").parent().parent().find("div.col_headings div.col_heading").slice(minCol-1,maxCol).addClass("selected_heading");

    //"Select" dragged cells' row headings
    $j("div.active_sheet").parent().find("div.row_headings div.row_heading").slice(relativeMinRow-1,relativeMaxRow).addClass("selected_heading");

    //Update the selection display e.g A3:B2
    var selection = "";
    selection += (num2alpha(minCol).toString() + minRow.toString());

    if(maxRow != minRow || maxCol != minCol)
        selection += (":" + num2alpha(maxCol).toString() + maxRow.toString());

    $j('#selected_cell').text(selection);
}

/* search_matched_spreadsheets_content.html.erb calls with a third argument - fileIndex = item_id
will have more than one spreadsheet_container div */
function activateSheet(sheet, sheetTab, fileIndex) {
    var root_element = null;
    if (sheetTab == null) {
        var i = sheet - 1;
        if (fileIndex == null) {
            sheetTab = $j("a.sheet_tab:eq(" + i + ")");
            /* this is entered only when coming from a search_matched_spreadsheets_content.html.erb,
             being the only caller with a third argument (fileIndex).
             Handles the case where there are many spreadsheet containers in the page, not just one.
             */
        } else {
            sheetTab = $j("a.sheet_tab." + fileIndex + ":eq(" + i + ")");
            root_element = sheetTab.closest("div.spreadsheet_container");
        }
    } else {
         root_element = sheetTab.closest("div.spreadsheet_container");
    }

    var sheetIndex = sheetTab.attr("index");


    //Clean up

    //Deselect previous tab
    $j('a.selected_tab').removeClass('selected_tab');

    //Disable old table + sheet
    $j('.active_sheet').removeClass('active_sheet');

    //Hide sheets
    if (root_element == null) {
        //gets here on file explore
        $j('div.sheet_container').hide();
    } else {
        //gets here from search results preview
        $j('div.sheet_container', root_element).hide();
    }
    //Hide paginates
    $j('div.pagination').hide();

    //Select the tab
    sheetTab.addClass('selected_tab');

    //Show the sheet
    $j("div.sheet_container#spreadsheet_" + sheetIndex).show();

    //Show the sheet paginate
    $j("div#paginate_sheet_" + sheetIndex).show();

    var activeSheet = $j("div.sheet#spreadsheet_" + sheetIndex);

    //Show the div + set sheet active
    activeSheet.addClass('active_sheet');

    //Reset scrollbars
    activeSheet.scrollTop(0).scrollLeft(0);

    //Set table active
    activeSheet.children("table.sheet").addClass('active_sheet');

    //Reset variables
    isMouseDown = false,
        startRow = 0,
        startCol = 0,
        endRow = 0,
        endCol = 0;

    return false;
}

function changeRowsPerPage(){
    var current_href = window.location.href;
    if (current_href.endsWith('#'))
        current_href = current_href.substring(0,current_href.length-1);

    var update_per_page = $j('#per_page')[0].value;
    var update_href = '';
    if (current_href.match('page_rows') == null){
        update_href = current_href.concat('&page_rows='+update_per_page);
    }else{
        var href_array = current_href.split('?');
        update_href = update_href.concat(href_array[0]);
        var param_array = [];
        if (href_array[1] != null){
            param_array = href_array[1].split('&');
            update_href = update_href.concat('?');
        }

        for (var i=0;i<param_array.length;i++){
            if(param_array[i].match('page_rows') == null){
                update_href = update_href.concat('&' + param_array[i]);
            }else{
                update_href = update_href.concat('&page_rows='+update_per_page);
            }
            //go to the first page
            if(param_array[i].match('page=') != null){
                update_href = update_href.concat('&page=1');
            }
        }
    }


    window.location.href = update_href;
}

// In the case of having pagination.
// To get the rows relatively to the page. E.g. minRow = 14, perPage = 10 => relativeMinRow = 4
function relativeRows(minRow, maxRow, sheetNumber){
    var current_page = null;
    if (sheetNumber != null)
        current_page = currentPage(sheetNumber);

    var relativeMinRow = minRow % perPage;
    var relativeMaxRow = maxRow % perPage;
    var minRowPage = parseInt(minRow/perPage) + 1;
    var maxRowPage = parseInt(maxRow/perPage) + 1;
    if (relativeMinRow == 0){
        relativeMinRow = perPage;
        minRowPage -=1;
    }
    if (relativeMaxRow == 0){
        relativeMaxRow = perPage;
        maxRowPage -=1;
    }

    //This is for the case of having minRow and maxRow in different pages.
    if (current_page != null && minRowPage < maxRowPage ){
        if (current_page == minRowPage){
            relativeMaxRow = perPage;
        }else if (current_page == maxRowPage){
            relativeMinRow = 1;
        }else if (current_page > minRowPage && current_page < maxRowPage){
            relativeMaxRow = perPage;
            relativeMinRow = 1;
        }
    }
    return [relativeMinRow, relativeMaxRow];
}

function displayRowsPerPage(){
    paginations = document.getElementsByClassName('pagination');
    if (paginations.length > 0){
        $j('#rows_per_page').show();
    }
}

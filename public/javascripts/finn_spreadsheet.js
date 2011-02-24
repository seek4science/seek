var $j = jQuery.noConflict();

$j(document).ready(function ($) {
  //Worksheet tabs
  $("a.sheet_tab")
    .click(function () {
      $('a.selected_tab').removeClass('selected_tab'); //deslect old tab
      $(this).addClass('selected_tab'); //select the tab
      $('.active_sheet').removeClass('active_sheet'); //disable old table
      $('div.sheet').hide(); //hide sheets
      //Show the div
      $("#spreadsheet_" + $(this).html()).show();
      //Set table active
      $("#spreadsheet_" + $(this).html() + " table").addClass('active_sheet');
      //Deselect any cells
      $("table.active_sheet td.selected_cell").removeClass("selected_cell");
      //Clear selection box
      $('#selection_data').val("");
      //Record current sheet in annotation form
      $('input#sheet_id').attr("value",$(this).attr("index"));
      //Reset variables
      isMouseDown = false,
      startRow = 0,
      startCol = 0,
      endRow = 0,
      endCol = 0,
      minRow = 0,
      minCol = 0,
      maxRow = 0,
      maxCol = 0;
      return false;
    });
  //Selecting cells
  
  var isMouseDown = false,
    startRow,
    startCol,
    endRow,
    endCol,
    minRow,
    minCol,
    maxRow,
    maxCol;

  $("table.sheet td.cell")
    .mousedown(function () {
      isMouseDown = true;
      $("table.active_sheet .selected_cell").removeClass("selected_cell");
      $("table.active_sheet .selected_heading").removeClass("selected_heading");
      minRow = 0;
      maxRow = 0;
      minCol = 0;
      maxCol = 0;
      startRow = parseInt($(this).attr("row"));
      startCol = parseInt($(this).attr("col")); 
      minRow = startRow;
      minCol = startCol;
      $(this).addClass("selected_cell");
      //"Select" cell's column headings
      $("table.active_sheet th").slice(minCol,minCol+1).addClass("selected_heading");      
      //"Select" cell's row headings
      $("table.active_sheet td.row_heading").slice(minRow-1,minRow).addClass("selected_heading");
      
      //Update the cell info box to contain either the value of the cell or the formula
      if($(this).attr("title"))
      {
        $('#cell_info').val("=" + $(this).attr("title"));
      }
      else
      {
        $('#cell_info').val($(this).html());
      }
      return false; // prevent text selection
    })
    .mouseover(function () {
      if (isMouseDown) {
        endRow = parseInt($(this).attr("row"));
        endCol = parseInt($(this).attr("col"));
        maxRow = endRow;
        maxCol = endCol;
        
        //To ensure minRow/mincol is always the smallest of the pair
        // no matter which direction the box is dragged
        if(endRow <= startRow) {
          minRow = endRow;
          maxRow = startRow;
        }
         
        if(endCol <= startCol) {
          minCol = endCol;
          maxCol = startCol;
        }
       
        //Clear currently selected cells
        $("table.active_sheet .selected_cell").removeClass("selected_cell");
        $("table.active_sheet .selected_heading").removeClass("selected_heading");
        
        //"Select" dragged cells
        $("table.active_sheet tr").slice(minRow,maxRow+1).each(function() {
          $(this).children("td.cell").slice(minCol-1,maxCol).addClass("selected_cell");
        });
        
        //"Select" dragged cells' column headings
        $("table.active_sheet th").slice(minCol,maxCol+1).addClass("selected_heading");
        
        //"Select" dragged cells' row headings
        $("table.active_sheet td.row_heading").slice(minRow-1,maxRow).addClass("selected_heading");

        //DEBUG
        $('#debug').html(
          "r1 " + minRow +
          ", r2 " + maxRow +
          ", c1 " + minCol +
          ", c2 " + maxCol + " ---- " +
          "e " + endCol +
          ", s " +startCol          
        );
      }    
    });

  $(document)
    .mouseup(function () {
      if (isMouseDown)
      {
        
        isMouseDown = false;
        //Hide annotations
        $('div.annotation').hide();
        
        //Update the selection display e.g A3:B2
        selection = "";
        selection += (num2alpha(minCol).toString() + minRow.toString());
        
        if(maxRow > 0 && maxCol > 0)
          selection += (":" + num2alpha(maxCol).toString() + maxRow.toString());
          
        $('#selection_data').val(selection);
        
        //Update cell coverage in annotation form
        $('input#cell_coverage').attr("value",selection);
      }
    });
});

function num2alpha(col)
{
  col = col-1; //To make it 0 indexed.
  var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var result = "";
    
  while (col > -1)
  {
    letter = (col % 26);
    result = alphabet.charAt(letter).toString() + result;
    col = ((col - (col % 26)) / 26) - 1;
  }
  return result;
}

function show_annotation(id,x,y)
{
  $j("#annotation_" + id).css('left',x+30);  
  $j("#annotation_" + id).css('top',y);
  $j("#annotation_" + id).show();  
}
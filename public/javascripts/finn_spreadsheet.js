var $j = jQuery.noConflict(); //To prevent conflicts with prototype

$j(document).ready(function ($) {
  //To disable text-selection
  //http://stackoverflow.com/questions/2700000/how-to-disable-text-selection-using-jquery
  $.fn.disableSelection = function() {
      $(this).attr('unselectable', 'on')
             .css('-moz-user-select', 'none')
             .each(function() { 
                 this.onselectstart = function() { return false; };
              });
  };

  
  //Record current sheet in annotation form
  $('input#annotation_sheet_id').attr("value",0);
  
  //Worksheet tabs  
  $("a.sheet_tab")
    .click(function () {
      //Hide annotations
      $('div.annotation').hide();
      $('#annotation_container').hide();    
      
      //Deselect previous tab
      $('a.selected_tab').removeClass('selected_tab'); 
      
      //Select the tab
      $(this).addClass('selected_tab');
      
      //Disable old table + sheet
      $('.active_sheet').removeClass('active_sheet');
      
      //Hide sheets
      $('div.sheet').hide();
      
      var sheetName = $(this).html().replace(" ","_");
      var activeSheet = $("div#spreadsheet_" + sheetName);
      
      //Show the div + set sheet active
      activeSheet.show().addClass('active_sheet');
      
      //Reset scrollbars
      activeSheet.scrollTop(0).scrollLeft(0);
      
      //Set table active
      activeSheet.find("table").addClass('active_sheet');

      //Deselect any cells
      $("table.active_sheet td.selected_cell").removeClass("selected_cell");
      
      //Clear selection box
      $('#selection_data').val("");
      
      //Clear cell info box
      $('#cell_info').val("");      
      
      //Record current sheet in annotation form
      $('input#annotation_sheet_id').attr("value",$(this).attr("index"));
      
      //Reset variables
      isMouseDown = false,
      startRow = 0,
      startCol = 0,
      endRow = 0,
      endCol = 0;
      return false;
    })
  ;
  
  
  //Selecting cells    
  var isMouseDown = false,
    startRow,
    startCol,
    endRow,
    endCol;

  $("table.sheet td.cell")
    .mousedown(function () {
      isMouseDown = true;
      startRow = parseInt($(this).attr("row"));
      startCol = parseInt($(this).attr("col")); 
      select_cells(startCol, startRow, startCol, startRow);
      
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
    .mouseover(function (e) {
      if (isMouseDown) {
        endRow = parseInt($(this).attr("row"));
        endCol = parseInt($(this).attr("col"));

        select_cells(startCol, startRow, endCol, endRow);
        /*
        var spreadsheetContainer = $('div.spreadsheet_container');
        var scroll = false;
        if(e.pageX >= (spreadsheetContainer.position().left + spreadsheetContainer.outerWidth())-100)
        {
          $('div.active_sheet').scrollLeft($('div.active_sheet').scrollLeft()+10);
          scroll = true;
        }
        if(e.pageY >= (spreadsheetContainer.position().top + spreadsheetContainer.outerHeight())-100)
        {
          $('div.active_sheet').scrollTop($('div.active_sheet').scrollTop()+10);
          scroll = true;
        }
        if(scroll)
        {
          $(this).trigger('mouseover', e);
          $(this).html(Math.random());
        }
        */
      }    
    })
  ;  
  
  //Draggable annotations
  var dragged;
  var dragX, dragY;
  var isDragging = false;
  $('#annotation_drag')
    .mousedown(function (e) {
      isDragging = true;
      dragX = e.pageX - $(this).offset().left;
      dragY = e.pageY - $(this).offset().top;
      dragged = $('#annotation_container');
    })
    .disableSelection()    
  ;

  $(document)
    .mouseup(function () {
      if (isMouseDown)
      {        
        isMouseDown = false;
        //Hide annotations
        $('#annotation_container').hide();    
        $('div.annotation').hide();   
      }
      if (isDragging)
      {
        isDragging = false;
        dragged = null;
      } 
    })
    .mousemove(function (e) {
      if (isDragging)
      {
        dragged.offset({ top: e.pageY-dragY, left: e.pageX-dragX });
      }
    })
  ;
    
  $('input#selection_data')
    .keyup(function(e) {
      if(e.keyCode == 13) {
        select_range($(this).val());   
      }
    })
  ;
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


function alpha2num(col)
{
  var result = 0;
  for(var i = col.length-1; i >= 0; i--){
    result += Math.pow(26,((col.length - 1) - i)) * (String.charCodeAt(col.charAt(i)) - 64);
  }
  return result;
}


//To display the annotations
function show_annotation(id,x,y)
{
  var annotation_container = $j("#annotation_container");
  var annotation = $j("#annotation_" + id);
  annotation_container.css('left',x+20);  
  annotation_container.css('top',y-20);
  annotation_container.show();
  annotation.show();  
}



function select_range(range)
{
  
  
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
  

  if(startRow && startCol && endRow && endCol)
    select_cells(startCol, startRow, endCol, endRow);
    
  //Scroll to selected cells
  row = $j("table.active_sheet tr").slice(startRow,endRow+1).first();
  cell = row.children("td.cell").slice(startCol-1,endCol).first();
  
  $j('div.active_sheet').scrollTop(row.position().top + $j('div.active_sheet').scrollTop() - 500);
  $j('div.active_sheet').scrollLeft(cell.position().left + $j('div.active_sheet').scrollLeft() - 500);    
}

function select_cells(startCol, startRow, endCol, endRow)
{
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

  //Clear currently selected cells
  $j(".selected_cell").removeClass("selected_cell");
  $j(".selected_heading").removeClass("selected_heading");
  
  //"Select" dragged cells
  $j("table.active_sheet tr").slice(minRow,maxRow+1).each(function() {
    $j(this).children("td.cell").slice(minCol-1,maxCol).addClass("selected_cell");
  });
  
  //"Select" dragged cells' column headings
  $j("table.active_sheet th").slice(minCol,maxCol+1).addClass("selected_heading");
  
  //"Select" dragged cells' row headings
  $j("table.active_sheet td.row_heading").slice(minRow-1,maxRow).addClass("selected_heading");
  
  //Update the selection display e.g A3:B2
  selection = "";
  selection += (num2alpha(minCol).toString() + minRow.toString());
  
  if(maxRow != minRow || maxCol != minCol)
    selection += (":" + num2alpha(maxCol).toString() + maxRow.toString());
    
  $j('#selection_data').val(selection);
  
  //Update cell coverage in annotation form
  $j('input#annotation_cell_coverage').attr("value",selection);
}

function toggle_annotation_form(annotation_id)
{
  var elem = 'div#annotation_' + annotation_id

  $j(elem + ' div.annotation_text').toggle();
  $j(elem + ' div.annotation_edit_text').toggle();
  $j(elem + ' #annotation_controls').toggle();
}
  
  
function show_annotation_stub(id, sheet, range)
{
  //Hide annotations
  $j('div.annotation').hide();
  //Go to the right sheet  
  $j("a.sheet_tab:eq(" + sheet +")").trigger('click');      
  //Select the cell range
  select_range(range);
  //Show annotation in middle of sheet
  var cells = $j('.selected_cell');
  show_annotation(id,
    cells.position().left + cell.outerWidth(),
    cells.position().top);
}

function plot_selected_cells(target_element,width,height) {
    plot_cells(target_element,width,height);
    $j("div.spreadsheet_popup").hide();
    $j("div#plot_panel").show();
}

function generate_json_data() {
    var cells = $j('td.selected_cell');
    var columns = $j('.col_heading.selected_heading').size();
    var headings;
    var rows = new Array();
    var colors = ["red","blue","green","cyan","magenta","darkgreen"]

    for (var i=0; i<cells.size(); i += columns) {
        var row = new Array();
        for (var j=0;j<columns;j+=1) {
            row.push(cells.eq(i + j).html())
        }
        if (i==0) {
            headings=row;
        }
        else {
            rows.push(row);
        }
    }

    var result = new Array();
    var json;

    for (var col=1;col<headings.size();col++) {

        var data=new Array();
        for (row=0;row<rows.size();row++) {
            var r = rows[row];

            data.push([parseFloat(r[0]),parseFloat(r[col])]);
        }
        json = {
            label : headings[col],
            data: data
        }

        if (col<colors.size()) {
            json["color"]=colors[col-1];
            json["curvedLines"]={show:true}
        }
        result.push(json);
    }
    return result;
}

function set_text_annotation_content() {
    var cells = $j('td.selected_cell');
    var columns = $j('.col_heading.selected_heading').size();
    var text;
    for(var i = 0; i < cells.size(); i += columns)
    {
    for(var j = 0; j < columns; j += 1)
    {
    text += (cells.eq(i + j).html() + "\t");
    }
    text += "\n";
    }
    $j("textarea.annotation_content_class").val(text);
}

function plot_cells(target_element,width,height)
{
    set_text_annotation_content();

    var json_data = generate_json_data();
    var element = $j("#"+target_element);
    element.width(width);
    element.height(height);

    var options = { series: {
        curvedLines: {
            active: true
        }
    }
    };

    $j.plot(element,json_data,options);
}
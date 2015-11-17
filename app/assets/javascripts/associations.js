function optionsFromArray(array) {
    var html = '';

    for(var i = 0; i < array.length; i++)
        html += '<option value="' + array[i][1] + '">' + array[i][0] + '</option>';

    return html;
}

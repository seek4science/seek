
function detectFileFormat(image_id){
    var file_path_array = $(image_id).value.split('.');
    var file_format = file_path_array[file_path_array.length -1];
    if (file_format.toLowerCase() != 'jpg'.toLowerCase() && file_format.toLowerCase() != 'gif'.toLowerCase() && file_format.toLowerCase() != 'png'.toLowerCase()){
        $(image_id).value = '';
        alert('Only jpg, gif and png formats are supported.');
    }
}
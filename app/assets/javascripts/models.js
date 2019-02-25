function detectFileFormat(image_id) {
    var image = $j('#' + image_id);
    var parts = image.val().split('.');
    var extension = parts[parts.length - 1].toLowerCase();
    if (extension !== 'jpg' &&
        extension !== 'gif' &&
        extension !== 'png') {
        image.val('');
        alert('Only jpg, gif and png formats are supported.');
    }
}
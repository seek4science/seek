// -------------------------
// Multiple File Upload
// -------------------------


function MultiSelector(list_target,object_name,method) {
    this.list_target = list_target;
    //this.count = 0;
    this.id_file = 0;
    this.id_url = 0;
    this.object_name = object_name;
    this.method = method;

    this.addElement = function(element) {
        if (element.tagName == 'INPUT' && element.type == 'file') {
            element.name = 'content_blob[file_' + (this.id_file++) + ']';
            element.multi_selector = this;
            element.onchange = function() {
                var new_element = document.createElement('input');
                new_element.type = 'file';
                this.parentNode.insertBefore(new_element, this);
                this.multi_selector.addElement(new_element);
                this.multi_selector.addListRow(this,this.multi_selector.object_name,this.multi_selector.method);
                this.style.position = 'absolute';
                this.style.left = '-1000px';
            };

            this.current_file_element = element;
            this.current_element  = element;
        } else{
            if (element.tagName == 'INPUT' && element.type == 'text') {
                element.name = 'content_blob[url_' + (this.id_url++) + ']';
                var original_filename_element = document.getElementsByName('content_blob[original_filename_' + (this.id_url -1) + ']')[0];
                element.multi_selector = this;

                this.current_url_element = element;
                this.current_original_filename_url_element = original_filename_element;
                this.current_element  = element;
            }else{
                alert('Error: neither a file input element nor a text field for file url');
            }


        }
    };
    this.addListRow = function(element,object_name,method) {
        var to_add_radio;
        if(typeof object_name == "undefined" || typeof method == "undefined"){
           to_add_radio = false ;
        }else{
           to_add_radio = true;
        }
        var new_row = document.createElement('tr');

        if (to_add_radio){
            var new_col1 = document.createElement('td');
            new_row.appendChild(new_col1);

            var new_row_radio =  document.createElement('input');
            new_row_radio.type='radio';
            new_row_radio.name = object_name + '['+ method +']';
            new_row_radio.id = object_name + '_'+ method;//'model_id_image';
            new_row_radio.title = "selected as image";

        }


        var new_col2 = document.createElement('td');
        var new_col3 = document.createElement('td');
        var new_col4 = document.createElement('td');


         new_row.appendChild(new_col2);
         new_row.appendChild(new_col3);
         new_row.appendChild(new_col4);




        var new_row_button = document.createElement('a');
        new_row_button.title = 'Remove This File';
        new_row_button.href = '#';
        new_row_button.innerHTML = 'Remove';
        new_row.element = element;
        new_row_button.onclick = function() {
            this.parentNode.parentNode.element.parentNode.removeChild(this.parentNode.parentNode.element);
            this.parentNode.parentNode.parentNode.removeChild(this.parentNode.parentNode);
            return false;
        };
        new_col4.appendChild(new_row_button);


        new_col2.innerHTML = '<img src="/images/file_icons/small/genericGray.png">';
        if (element.type =='text'){
           var original_filename =document.getElementsByName('content_blob[original_filename_' + (this.id_url - 2) + ']')[0].value;
           new_col3.innerHTML = (original_filename || element.value);
        }else
            new_col3.innerHTML =  element.value.split(/\\/)[element.value.split(/\\/).length - 1];
        new_col3.style.textAlign = "left";



        var file_type = new_col3.innerHTML.split('.')[new_col3.innerHTML.split('.').length-1];
         if (to_add_radio){
            if(file_type=="jpg" || file_type=="jpeg" ||file_type=="bmp" ||file_type=="png" ||file_type=="gif" ||file_type=="tif" ||file_type=="tiff"){
            new_row_radio.value = new_col3.innerHTML;
            new_col1.appendChild(new_row_radio);
            }
         }

        this.list_target.appendChild(new_row);
    };
}
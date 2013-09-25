/* Based on source code from the Blog post by Mike Thomas at: http://atomicrobotdesign.com/blog/web-development/controlling-html-using-the-jquery-ui-slider-and-links/ */

$.noConflict();

jQuery(document).ready(function($) {


    $(function() {

        //IMG ARRAY

        var imgarray = [];

        $("#zoom img").each(function () {
            var img = '#' + $(this).attr('id');
            imgarray.push(img);

        });

        // same order as scales_arr
        imgarray.reverse();


        var curImage = imgarray[0];
        var previousValue;
        var val=0;

        // slider value<=>scale string
        //var scales_arr = ["cell","intercellular","liverLobule","liver","organism","all"];//["organism","liver","liverLobe","liverLobule","intercellular","cell"];
        var scale_id;

        //slider mit 5 stufen, regler ist standardm��ig ganz oben
        //the jQuery slider has a build in event that fires every time the handle is moved on the slider called slide.
        //What we have set up here is that every time the slider handle is moved, we get the value and then run a function called valCheck.
        $("#slider").slider({
            orientation: "vertical",
            min: 0,
            max: (scales_arr.length - 1),
            value: current_scale,
            animate:true,
            slide: function (event, ui) {
                //alert("#slider.slide"+ ui.value) ;
                previousValue = val;
                val = ui.value;
                //$('#scale').val(scales_arr[val]) ; // change scale filter for searching
                //valCheck();
                scale_id = "#" + scales_arr[val];
                $(scale_id).click();
            },
        });



        //valCheck() just checks the variable val and then runs a function called imageSwap, passing in the current image and the image we want to display,
        //then we change the current image to the new image.
        function valCheck() {
            if (val > previousValue) {
                //alert("val =" + val + "|| previousValue=" + previousValue);
                imageSwap3(curImage, imgarray[val]);
                curImage = imgarray[val];

            }

            else {
                // alert("val =" + val + " &&  previousValue=" + previousValue);
                imageSwap(curImage, imgarray[val]);
                curImage = imgarray[val];


            }


        }

        //ANIMATION if images are changing!!
        //we�re just passing in the current image and the new image, fading out the current one and then fading in the new image
        function imageSwap(curImage, newImage) {
            /* $(curImage).fadeOut();
             $(newImage).fadeIn(); */
            $(curImage).css({'opacity':'1'});
            $(newImage).css({'opacity':'0'});
            $(newImage).css({'height':'25%', 'marginLeft':'200px', 'marginTop':'105px'});
            $(curImage).css({'display':'inline'});
            $(newImage).css({'display':'inline'});
            $(curImage).animate({
                height: "250%",
                marginLeft: "-120px",
                marginTop: "-222px",
                opacity:'0'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                    //$(this).hide();
                }
            });
            $(newImage).animate({
                height: "100%",
                marginLeft: "0px",
                marginTop: "0px",
                opacity:'1'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                    //this.show();
                }
            });


        }

        function imageSwap2(curImage, newImage) {
            $(curImage).fadeOut();
            $(newImage).fadeIn();

        }

        function imageSwap3(curImage, newImage) {
            $(curImage).css({'opacity':'1'});
            $(newImage).css({'opacity':'0'});
            $(newImage).css({'height':'250%', 'marginLeft':'-120px', 'marginTop':'-222px'});
            $(curImage).css({'display':'inline'});
            $(newImage).css({'display':'inline'});
            $(curImage).animate({
                height: "25%",
                marginLeft: "200px",
                marginTop: "105px",
                opacity:'0'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                    //$(this).hide();
                }
            });
            $(newImage).animate({
                height: "100%",
                marginLeft: "0px",
                marginTop: "0px",
                opacity:'1'
            }, {
                duration: 2000,
                queue: false,
                complete: function() {
                    //this.show();
                }
            });

            /* alert(newImage + curImage); */
            // alert(val+',' + previousValue);

        }

        //ANIMATION if images are changing!!
        //we�re just passing in the current image and the new image, fading out the current one and then fading in the new image
        function imageSwapElina(curImage, newImage) {
            /* $(curImage).fadeOut();
             $(newImage).fadeIn(); */
            $(curImage).css({'opacity':'1'});

            $(curImage).animate({
                height: "250%",
                marginLeft: "-50px",
                marginTop: "-150px",

            }, 2000);

            $(curImage).fadeOut();

            $(newImage).fadeIn(2000, function() {
                $(newImage).animate({
                    height: "100%",
                    marginLeft: "100px",
                    marginTop: "0px",
                    queue:false,

                }, 1000);
            });

        }



        //We�re just setting val to be the same as num and then running valCheck when the user clicks one of the links, otherwise, the images would only swap when the user slides the handle back and forth. Now the image swap will work if the user either clicks the links or moves the slider.
        function moveSlider(e, num) {
            e.preventDefault();
            $('#slider').slider(
                'value',
                [num]
            );
            val = num;

            // scale_id = "#" + scales_arr[val];
            // $(scale_id).click();
            valCheck();
        }

        $('#organism').click(function(e) {
            moveSlider(e, 4);
        });
        $('#liver').click(function(e) {
            moveSlider(e, 3);
        });
        $('#liverlobule').click(function(e) {
            moveSlider(e, 2);
        });
        $('#intercellular').click(function(e) {
            moveSlider(e, 1);
        });
        $('#cell').click(function(e) {
            moveSlider(e, 0);
        });
        $('#all').click(function(e) {
            moveSlider(e, 5);
        });

        //initial status
        previousValue = $('#slider').slider(
            'value'
        );
        val = current_scale;
        scale_id = "#" + scales_arr[val];
        $(scale_id).click();

    });





});

function load_tabs() {
    var tabberOptions = {'onLoad':function() {

    }};
    tabberAutomatic(tabberOptions);
}
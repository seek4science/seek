$.noConflict();

jQuery(document).ready(function($) {



	$(function() {

	//IMG ARRAY

			var imgarray = [];

			$("#zoom img").each(function () {
			   var img = '#'+$(this).attr('id');
			   imgarray.push(img);
			});
			 var infoarray =[];
			 $(".information").each(function () {
			   var info = '#'+$(this).attr('id');
			   infoarray.push(info);
			});


			/* alert(infoarray + imgarray);  */


		//Variablen festlegen, sichtabres Bild ist immer zuerst Bild-0
		var curImage = imgarray[0];
		var curInfo = infoarray[0];
		var previousValue;
		var val;

		/* $('img').click(function() {
			alert(curImage + curInfo);
		}); */


		//slider mit 5 stufen, regler ist standardm��ig ganz oben
		//the jQuery slider has a build in event that fires every time the handle is moved on the slider called slide.
		//What we have set up here is that every time the slider handle is moved, we get the value and then run a function called valCheck.
		$( "#slider" ).slider({
			orientation: "vertical",
			min: 0,
			max: 5,
			value: 0,
			animate:true,
			slide: function (event, ui) {
				previousValue = val;
				val = ui.value;
				valCheck();
				 },
			});



		//valCheck() just checks the variable val and then runs a function called imageSwap, passing in the current image and the image we want to display,
		//then we change the current image to the new image.
		function valCheck(){
			if (val < previousValue) {
				imageSwap3(curImage, imgarray[val]);
				curImage = imgarray[val];
				infoSwap(curInfo, infoarray[val]);
				curInfo = infoarray[val];
				//alert( val+'<'+previousValue);
				}

			else {
				imageSwap(curImage, imgarray[val]);
				curImage = imgarray[val];
				infoSwap(curInfo, infoarray[val]);
				curInfo = infoarray[val];
				//alert( val+'>'+previousValue);

				}



		}
		//ANIMATION if images are changing!!
		//we�re just passing in the current image and the new image, fading out the current one and then fading in the new image
		function imageSwap(curImage, newImage){
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
					complete: function(){
						//$(this).hide();
					}
				});
			$(newImage).animate({
				height: "100%",
				marginLeft: "100px",
				marginTop: "0px",
				opacity:'1'
				}, {
					duration: 2000,
					queue: false,
					complete: function(){
						//this.show();
					}
				});


		}

		function imageSwap2(curImage, newImage){
			 $(curImage).fadeOut();
			$(newImage).fadeIn();

		}

		function imageSwap3(curImage, newImage){

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
					complete: function(){
						//$(this).hide();
					}
				});
			$(newImage).animate({
				height: "100%",
				marginLeft: "100px",
				marginTop: "0px",
				opacity:'1'
				}, {
					duration: 2000,
					queue: false,
					complete: function(){
						//this.show();
					}
				});

				/* alert(newImage + curImage); */
				// alert(val+',' + previousValue);

		}
		//ANIMATION if images are changing!!
		//we�re just passing in the current image and the new image, fading out the current one and then fading in the new image
		function imageSwapElina(curImage, newImage){
			/* $(curImage).fadeOut();
			$(newImage).fadeIn(); */
			$(curImage).css({'opacity':'1'});

			$(curImage).animate({
				height: "250%",
				marginLeft: "-50px",
				marginTop: "-150px",

				}, 2000 );

			$(curImage).fadeOut();

			$(newImage).fadeIn(2000, function() {
				$(newImage).animate({
					height: "100%",
					marginLeft: "100px",
					marginTop: "0px",
					queue:false,

					}, 1000 );
					});

		}

		//#############

		 function infoSwap(curInfo, newInfo){
			$(curInfo).fadeOut(2000, function() {});
			$(newInfo).fadeIn(2000, function() {});

		}
		//We�re just setting val to be the same as num and then running valCheck when the user clicks one of the links, otherwise, the images would only swap when the user slides the handle back and forth. Now the image swap will work if the user either clicks the links or moves the slider.
 	 function moveSlider(e, num){
			e.preventDefault();
			$('#slider').slider(
				'value',
				[num]
			);
			val = num;
			valCheck();
		}

		 $('#organism').click(function(e) {
             alert('#organism');
		   moveSlider(e,0);
		 });
		 $('#liver').click(function(e) {
		   moveSlider(e,1);
		 });
		 $('#liverLobe').click(function(e) {
		   moveSlider(e,2);
		 });
		 $('#liverLobule').click(function(e) {
		   moveSlider(e,3);
		 });
		 $('#intercellular').click(function(e) {
		   moveSlider(e,4);
		 });
		 $('#cell').click(function(e) {
		   moveSlider(e,5);
		 });



	});

	//accordion

			$( ".information" ).accordion({
				header:'.slide',
				});

	/* Source Code: http://atomicrobotdesign.com/blog/web-development/controlling-html-using-the-jquery-ui-slider-and-links/ */
});
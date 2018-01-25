function prepareNames($inputs){
	var partners = [];
	for(var i =0; i< $inputs.length;i++){
		var partner = $inputs[i].value;
		if(partner == "Not Applicable")
			continue;
        partner = partner.replace(/ *\([^)]*\) */g, ""); //Remove brackets 
        partner = partner.replace(/ *\-[^]*\ */g, ""); //Remove dashes
        partners.push(partner);
	}

	partners = partners.filter( function( item, index, inputArray ) {
           return inputArray.indexOf(item) == index;
    });

    return partners;
}

function requestLogos(partners, callback){
	var images = [];
	var index = 0;
	for (var i = 0; i < partners.length; i++) {
		jQuery.ajax({
		     url:"https://mel.cgiar.org/dspace/getlogos",
		     data: {
		     	client_id:1,
				 client_secret: 'hello',
                 partners: partners[i],
			 },
		     dataType: 'jsonp',
		     success:function(json){
		     	 index++;
		         if(json.logo && json.logo.length > 38){//be sure logo available 
		            images.push(json.logo);
		         }
		         if(index == partners.length){
		            callback(images);
		         }
		     },
		     error:function(){
		     	index++;
		     }      
		});
	}
}

function appendImages(images){
	if(images.length > 0){
		jQuery('.partners-list .logos').prepend('<h5>Partners</h5>');
	}
	for(var i = 0; i < images.length; i++){
		jQuery('.partners-list .logos').append('<img src="' + images[i] + '" />');
	}
}

function checkPartners(){
  if(jQuery('.partners-list').length > 0){
     $inputs = jQuery('.partners-list .values input');
     var partners = prepareNames($inputs);
     requestLogos(partners, appendImages);
  }
}

function prepareNames($inputs) {
    var partners = [];
    //Fix names
    for (var i = 0; i < $inputs.length; i++) {
        var partner = $inputs[i].value;
        if (partner == "Not Applicable")
            continue;
        partner = partner.replace(/ *\([^)]*\) */g, ""); //Remove brackets
        partner = partner.replace(/ *\-[^]*\ */g, ""); //Remove dashes
        partners.push(partner);
    }

    //Remove duplicates
    partners = partners.filter(function (item, index, inputArray) {
        return inputArray.indexOf(item) == index;
    });

    return partners;
}

function requestLogos(partners, callback) {
    var images = [];
    jQuery.ajax({
        url: "https://mel.cgiar.org/dspace/getpartnerlogos",
        data: {
            client_id: 1,
            client_secret: 'hello',
            partners: partners,
            height: 48,
        },
        dataType: 'jsonp',
        success: function (json) {
            if (json.data) {
                $.each(json.data, function (key, value) {
                    images.push(value.logo);
                });
                callback(images);
            }
        },
        error: function () {
        }
    });
}

function appendImages(images) {
    for (var i = 0; i < images.length; i++) {
        jQuery('.partners-list .logos').append('<img src="' + images[i] + '" />');
    }
}

function checkPartners() {
    if (jQuery('.partners-list').length > 0) {
        $inputs = jQuery('.partners-list .values input');
        var partners = prepareNames($inputs);
        requestLogos(partners, appendImages);
    }
}

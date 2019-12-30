function prepareNames($inputs) {
    var partners = [];
    for (var i = 0; i < $inputs.length; i++) {
        var partner = $inputs[i].value;
        if (partner == "Not Applicable")
            continue;
        partner = partner.replace(/ *\([^)]*\) */g, ""); //Remove brackets
        partner = partner.replace(/ *\-[^]*\ */g, ""); //Remove dashes
        partners.push(partner);
    }

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
        jQuery('.partners-list-logos').append('<img src="' + images[i] + '" />');
    }
}

function checkPartners() {
    if (jQuery('.partners-list').length > 0) {
        $inputs = jQuery('.partners-list .values input');
        var partners = prepareNames($inputs);
        requestLogos(partners, appendImages);
    }
}

function Visits() {
    var popoverContent = 'Dear Visitor, this site complies with the European Union General Data Protection Regulation <a href=\'https://www.eugdpr.org\' target=\'_blank\'>(GDPR)</a> and all Internet Protocol (IP) addresses collected with the purpose to generate the information charts (analytics) are anonymized and we cannot identify the user individually. <br>Country label \'\'Global\'\' refers to IP addresses not matched with any country.';
    var popover_table_style = '"border: solid 1px black;border-radius: 50%;padding: 1px 7px;cursor: pointer;" ';
    var GDPR_popover_table = '<i class="popovers" data-trigger="click" data-placement="top" style=' + popover_table_style +
        'data-content="'+popoverContent+'" ' +
        'data-container="body"> &#33;</i>';

    var popover_chart_style = '"border: solid 1px black;border-radius: 50%;padding: 1px 10px;cursor: pointer; padding-left: 7px;" ';
    var GDPR_popover_chart = '<i class="popovers" data-trigger="click" data-placement="top" style=' + popover_chart_style +
        'data-content="'+popoverContent+'" ' +
        'data-container="body"> &#33;</i>';

    var dspace_item_id = $('input[name=dspace_item_id]').val();
    var dspace_item_handle = $('input[name=dspace_item_handle]').val();

    if (($('input[name=dspace_item_id]').length > 0 && dspace_item_id != '') || ($('input[name=dspace_item_handle]').length > 0 && dspace_item_handle != '')) {
        GetVisit(dspace_item_id, dspace_item_handle);
        GetLocation(dspace_item_id, dspace_item_handle, 'visit');
    }

    function GetLocation(dspace_item_id, dspace_item_handle, type, call_back) {
        $.get("https://ipinfo.io", function (response) {
            response.dspace_item_id = dspace_item_id;
            response.dspace_item_handle = dspace_item_handle;
            response.type = type;
            AddVisit(response, call_back)

        }, "jsonp");
    }

    function AddVisit(response) {
        $.ajax({
            url: "https://mel.cgiar.org/dspace/adddspacevisit",
            data: {
                client_id: 1,
                client_secret: 'hello',
                response: response,
            },
            dataType: 'jsonp',
            success: function (json) {
            },
            error: function () {
            }
        });
    }

    function GetVisit(dspace_item_id, dspace_item_handle) {
        $.ajax({
            url: "https://mel.cgiar.org/dspace/getdspacevisits",
            data: {
                client_id: 1,
                client_secret: 'hello',
                dspace_item_id: dspace_item_id,
                dspace_item_handle: dspace_item_handle,
            },
            dataType: 'jsonp',
            success: function (json) {
                if (json.data) {
                    BuildVisitsTable(json.data)
                }
            },
            error: function () {

            }
        });
    }

    function BuildVisitsTable(data) {
        var html = '<div id="ItemStatistics_div" class="row" style="text-align: center; margin-top: 50px;">';
        var visitsTable =
            '<div class="col-md-6">' +
            '<table class="table table-striped table-bordered table-hover">' +
            '<thead>' +
            '<tr>' +
            '<th colspan="3" style="text-align: center;">Last 6 months ' + GDPR_popover_table + '</th>' +
            '</td>' +
            '</thead>' +
            '<tbody>' +
            '<tr>' +
            '<th style="text-align: center;">Country</th>' +
            '<th style="text-align: center;">Views</th>' +
            '<th style="text-align: center;">Downloads</th>' +
            '</tr>';
        if (data.length == 0) {
            visitsTable += '<tr><td colspan="3">Nothing to display</td></tr>';
            visitsTable += '</tbody></table></div>';
            html += visitsTable;
            html += '</div>';

            $('#aspect_artifactbrowser_ItemViewer_div_item-view').parent().append(html);
        } else {
            $.each(data.six_months_count, function (key, value) {
                visitsTable += '<tr>';
                visitsTable += '<td>' + key + '</td>';
                visitsTable += '<td>' + value.visit + '</td>';
                visitsTable += '<td>' + value.link + '</td>';
                visitsTable += '</tr>';
            });

            visitsTable += '</tbody></table></div>';
            html += visitsTable;

            html += '<div class="col-md-6"><div id="ChartContainer"></div></div>';
            html += '</div>';

            $('#aspect_artifactbrowser_ItemViewer_div_item-view').parent().append(html);
            initChart(data.all_time_count.visit, data.all_time_count.link);
        }
        $('.popovers').popover({html: true});

    }

    function initChart(visits, downloads) {
        Highcharts.setOptions({
            colors: Highcharts.map(Highcharts.getOptions().colors, function (color) {
                return {
                    radialGradient: {
                        cx: 0.5,
                        cy: 0.3,
                        r: 0.7
                    },
                    stops: [
                        [0, color],
                        [1, Highcharts.Color(color).brighten(-0.3).get('rgb')] // darken
                    ]
                };
            })
        });


        Highcharts.chart('ChartContainer', {
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie'
            },
            title: {
                text: 'All time ' + GDPR_popover_chart,
                useHTML: true
            },
            tooltip: {
                pointFormat: '<b>{point.y} </b>({point.percentage:.1f}%)'
            },
            plotOptions: {
                pie: {
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false,
                    },
                    showInLegend: true
                }
            },
            legend: {
                enabled: true,
                labelFormatter: function () {
                    return this.name + ': ' + this.y + ' (' + this.percentage.toFixed(1) + '%)';
                }
            },
            series: [{
                innerSize: '70%',
                data: [
                    {name: 'Views', y: visits, color: '#5090d0'},
                    {name: 'Downloads', y: downloads, color: '#5e7357'}
                ]
            }]
        });
    }
    $('.popovers').popover({html: true});

    $('body').on('click', '.send_cg_contact', function () {
        var email = $(this).data('contact_mail');
        var domain = $(this).data('contact_domain');
        window.location.href = 'mailto:' + email + '@' + domain;
    });
}

function item_map() {
    if ($('#item_map input:hidden').length > 0) {
        $('#item_map').css('height', '500px');
        var visualization_map = L.map('item_map').setView([0, 0], 2);
        L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}', {
            attribution: 'Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community'
        }).addTo(visualization_map);

        $.getJSON('/themes/MELSpace/countries.json', function (data) {
            var markers = {};

            $('#item_map input:hidden').each(function () {
                var iso = $(this).val();
                if (data.hasOwnProperty(iso) && data[iso].lat != null) {
                    markers[iso] = new L.marker([data[iso].lat, data[iso].lng]);

                    markers[iso].bindPopup(data[iso].name);
                    markers[iso].addTo(visualization_map);
                    markers[iso].on('mouseover', function (e) {
                        e.target.openPopup();
                    });
                    markers[iso].on('mouseout', function (e) {
                        e.target.closePopup();
                    });

                    markers[iso].on('click', function (e) {
                        e.target.openPopup();
                        visualization_map.setView([e.latlng.lat, e.latlng.lng], 4);
                    });
                }
            });
            visualization_map._handlers.forEach(function(handler) {
                handler.disable();
            });
        });
        $('body').on('click', '*', function(e){
            var target = $(e.target);
            var enable = false;
            if (target.hasClass('overlay-layer-parent') || target.parents('.overlay-layer-parent').length > 0)
                enable = true;
            else if (target.hasClass('item_map') || target.parents('.item_map').length > 0)
                return;

            if (enable) {
                if ($('.overlay-layer-parent:visible').length > 0) {
                    visualization_map._handlers.forEach(function (handler) {
                        handler.enable();
                    });
                    $('.overlay-layer-parent').hide();
                }
            } else {
                if ($('.overlay-layer-parent:visible').length === 0) {
                    visualization_map._handlers.forEach(function (handler) {
                        handler.disable();
                    });
                    $('.overlay-layer-parent').show();
                }
            }
        });
    } else {
        $('#item_map').remove();
    }
}
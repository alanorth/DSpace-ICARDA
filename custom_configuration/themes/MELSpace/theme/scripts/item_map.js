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
                        visualization_map.setView([e.latlng.lat, e.latlng.lng]);
                    });
                }
            });
        });
    }
}
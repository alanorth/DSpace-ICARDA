function Visits() {
    var popover_table_style = '"border: solid 1px black;border-radius: 50%;padding: 1px 7px;cursor: pointer;" ';
    var GDPR_popover_table = '<i class="popovers" aria-hidden="true" data-trigger="click" data-placement="top" ' +
            'style=' + popover_table_style +
            'data-content="Dear Visitor, this site complies with the European Union General Data Protection Regulation <a href=\'https://www.eugdpr.org/\' target=\'_blank\'>(GDPR)</a> and all Internet Protocol (IP) addresses collected with the purpose to generate the information charts (analytics) are anonymized and we cannot identify the user individually. <br>Country label “Gobal” refers to IP addresses not matched with any country." ' +
            'data-container="body" aria-describedby="popover300157"> &#33;</i>';

    var popover_chart_style = '"border: solid 1px black;border-radius: 50%;padding: 1px 10px;cursor: pointer; padding-left: 7px;" ';
    var GDPR_popover_chart = '<i class="popovers" aria-hidden="true" data-trigger="click" data-placement="top" ' +
            'style=' + popover_chart_style +
            'data-content="Dear Visitor, this site complies with the European Union General Data Protection Regulation <a href=\'https://www.eugdpr.org/\' target=\'_blank\'>(GDPR)</a> and all Internet Protocol (IP) addresses collected with the purpose to generate the information charts (analytics) are anonymized and we cannot identify the user individually. <br>Country label “Gobal” refers to IP addresses not matched with any country." ' +
            'data-container="body" aria-describedby="popover300157"> &#33;</i>';

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
                data: [
                    {name: 'Views', y: visits, color: '#5090d0'},
                    {name: 'Downloads', y: downloads, color: '#5e7357'}
                ]
            }]
        });
    }
    $('.popovers').popover({html: true});
}

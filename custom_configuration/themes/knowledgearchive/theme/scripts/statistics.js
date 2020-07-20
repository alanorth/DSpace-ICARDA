function statistics_charts() {
    // Override autoIncrement to allow pointInterval: 'month' and 'year'
    (function (H) {
        var pick = H.pick,
            useUTC = H.getOptions().global.useUTC,
            setMonth = useUTC ? 'setUTCMonth' : 'setMonth',
            getMonth = useUTC ? 'getUTCMonth' : 'getMonth',
            setFullYear = useUTC ? 'setUTCFullYear' : 'setFullYear',
            getFullYear = useUTC ? 'getUTCFullYear' : 'getFullYear';

        H.Series.prototype.autoIncrement = function () {

            var options = this.options,
                xIncrement = this.xIncrement,
                date,
                pointInterval;

            xIncrement = pick(xIncrement, options.pointStart, 0);

            this.pointInterval = pointInterval = pick(this.pointInterval, options.pointInterval, 1);

            // Added code for pointInterval strings
            if (pointInterval === 'month' || pointInterval === 'year') {
                date = new Date(xIncrement);
                date = (pointInterval === 'month') ?
                    +date[setMonth](date[getMonth]() + 1) :
                    +date[setFullYear](date[getFullYear]() + 1);
                pointInterval = date - xIncrement;
            }

            this.xIncrement = xIncrement + pointInterval;
            return xIncrement;
        };
    }(Highcharts));

    function initCountriesChart(data) {
        let countries = [];
        let views = [];
        let downloads = [];
        data.slice(0, 10).map((row) => {
            countries.push(row.country_iso);
            views.push(row.views);
            downloads.push(row.downloads);
        });
        Highcharts.chart('countries_chart', {
            colors: ["#1a4883", "#6ecad1"],
            chart: {
                type: 'bar'
            },
            title: {
                useHTML: true,
                text: '<div style="text-align: center;">Statistics by Country<br><small><i>Top 10</i></small></div>'
            },
            xAxis: {
                categories: countries,
                title: {
                    text: null
                }
            },
            yAxis: {
                min: 0,

                labels: {
                    overflow: 'justify'
                }
            },

            plotOptions: {
                bar: {
                    dataLabels: {
                        enabled: true
                    }
                }
            },


            series: [{
                name: 'Views',
                data: views
            }, {
                name: 'Downloads',
                data: downloads
            }]
        });
    }

    function initLast6MonthsChart(views, downloads, start_date) {
        start_date = Date.UTC(start_date.getFullYear(), start_date.getMonth(), 0);

        let chart_data = [{
            name: 'Views',
            data: Object.values(views),
            pointStart: start_date,
            pointInterval: 'month',
        }, {
            name: 'Downloads',
            data: Object.values(downloads),
            pointStart: start_date,
            pointInterval: 'month',
        }];

        Highcharts.chart('last_6_months_chart', {
            colors: ["#1a4883", "#6ecad1"],
            title: {
                useHTML: true,
                text: '<div style="text-align: center;">Statistics by month<br><small><i>Last 6 months</i></small></div>'
            },
            yAxis: {
                title: {
                    text: ''
                }
            },
            xAxis: {
                type: 'datetime',
            },
            tooltip: {
                formatter: function () {
                    return this.series.name + ': <b>' + this.y + '</b>';
                }
            },
            series: chart_data
        });
    }

    function initAllTimeChart(views, downloads) {
        Highcharts.chart('all_time_chart', {
            colors: ["#1a4883", "#6ecad1"],
            title: {
                useHTML: true,
                text: '<tspan style=";">All time</tspan>',
                align: 'center',
                verticalAlign: 'top'
            },
            tooltip: {
                pointFormat: '<b>{point.y}</b> ({point.percentage:.1f}%)'
            },
            plotOptions: {
                pie: {
                    dataLabels: {
                        enabled: false,
                    },
                    size: '80%',
                    showInLegend: true
                },
                showInLegend: true
            },
            series: [{
                type: 'pie',
                innerSize: '60%',
                data: [
                    ['Views', views],
                    ['Downloads', downloads]
                ]
            }]
        });
    }

    function dateToString(date) {
        let year = date.getFullYear();
        let month = (date.getMonth() + 1).toString();
        month = month.length === 1 ? '0' + month : month;
        let day = (date.getDate() + 1).toString();
        day = day.length === 1 ? '0' + day : day;
        return year + '-' + month + '-' + day;
    }

    let start_date = new Date();
    start_date.setDate(1);
    start_date.setMonth(start_date.getMonth() - 5);
    let end_date = new Date();
    end_date.setDate(1);

    let dspace_item_id = $('input[name=dspace_item_id]').val();
    if (dspace_item_id !== '' && dspace_item_id != null) {
        $.ajax({
            url: 'rest/statistics/items/' + dspace_item_id + '?aggregate=country&start_date=' + dateToString(start_date) + '&end_date=' + dateToString(end_date),
            success: function (data, status) {
                if (data.hasOwnProperty('statistics') && Array.isArray(data.statistics) && data.statistics.length === 1) {
                    let statistics = data.statistics[0];
                    initAllTimeChart(statistics.views, statistics.downloads);
                    initCountriesChart(statistics.countries);
                }
                if (data.hasOwnProperty('total_views_by_month') && data.hasOwnProperty('total_downloads_by_month')) {
                    initLast6MonthsChart(data.total_views_by_month, data.total_downloads_by_month, start_date);
                }
            }
        });
    }

    $('body').on('click', '.toggle-additional-statistics', function () {
        $(this).find('span').toggle();
        let additional_statistics = $('.additional-statistics');
        additional_statistics.slideToggle('slow');
        $(document.documentElement).animate({
            scrollTop: additional_statistics.offset().top
        }, 700);
    });
}

var encodeOnce = function(v) {
    return encodeURIComponent(v);
}

var encodeTwice = function(v) {
    return encodeURI(encodeOnce(v));
}

function customDataPageViews() {
    $("#customDataPageViews").DataTable({
        searching: false,
        sorting: false,
        paging: false,
        bPaginate: false,
        info: false,
        ajax: {
            url: matomo+"index.php?module=API&method=CustomDimensions.getCustomDimension&idSite="+siteId+"&period=range&date=2018-01-01,now&format=JSON&token_auth=anonymous&idDimension="+authorViewsDimensionId+"&expanded=1&segment=actionType%3D%3Dpageviews,actions%3D%3D;"+authorViewsDimensionName+"%3D@"+encodeTwice(author),
            dataSrc: function (json) {
                // console.log(json +" before loop");
                var requiredData = [];
                if (json) {
                    for (var i in json) {
                        var url = "https://";
                        var myLabel = json[i].label;
                        var myLabelArray = myLabel.split("||||");
                        json[i].label = myLabelArray[0];
                        json[i].documentName = myLabelArray[1];
                        json[i].linkHref = "<a href='" + url+decodeURIComponent(json[i].subtable[0].url) + "' target='_blank'>" + json[i].documentName + "</a>";
                    }
                }
                // console.log(json);
                return json;
            }
        },
        columns: [
            // {data: "label"},

            {data: "linkHref"},
            {data: "nb_visits"}
        ],
        columnDefs: [
            {
                className: "text-right",
                targets: [1]
            }
        ]
    });
}

function customDataDownloads() {
    $("#customDataDownloads").DataTable({
        searching: false,
        sorting: false,
        paging: false,
        bPaginate: false,
        info: false,
        ajax: {
            url: matomo+"index.php?module=API&method=CustomDimensions.getCustomDimension&idSite="+siteId+"&period=range&date=2018-01-01,now&format=JSON&token_auth=anonymous&idDimension="+authorViewsDimensionId+"&expanded=1&segment=actionType%3D%3Ddownloads,actions%3D%3D;"+authorViewsDimensionName+"%3D@"+encodeTwice(author),
            dataSrc: function (json) {
                // console.log(json +" before loop");
                var requiredData = [];
                if (json) {
                    for (var i in json) {
                        var url = "https://";
                        var myLabel = json[i].label;
                        var myLabelArray = myLabel.split("||||");
                        json[i].label = myLabelArray[0];
                        json[i].documentName = myLabelArray[1];
                        var params = (json[i].subtable[0].label).split("/", 5);
                        if (params) {
                            for (var j in params) {
                                if (params[j] !== "bitstream"){
                                    url += params[j] + "/";
                                }
                            }
                        }
                        json[i].linkHref = "<a href='" + url + "' target='_blank'>" + json[i].documentName + "</a>";
                    }
                }
                // console.log(json);
                return json;
            }
        },
        columns: [
            // { data: "label" },
            {data: "linkHref"},
            {data: "nb_visits"}
            // { data: "subtable[0].url" },
        ],
        columnDefs: [
            {
                className: "text-right",
                targets: [1]
            }
        ]
    });
}

function bindCountries() {
    $("#countries").DataTable({
        searching: false,
        sorting: false,
        paging: false,
        bPaginate: false,
        info: false,
        ajax: {
            url: matomo+"index.php?module=API&method=UserCountry.getCountry&idSite="+siteId+"&period=range&date=2018-01-01,now&format=JSON&segment=pageUrl=="+encodeOnce(pageURL)+"&filter_limit=10",
            dataSrc: ""
        },
        columns: [
            {data: "label"},
            // { data: "code" },
            {data: "nb_visits"}
            // { data: "nb_actions" }
        ],
        columnDefs: [
            {
                className: "text-right",
                targets: [1]
            }
        ]
    });
}

function bindCities() {
    $("#cities").DataTable({
        searching: false,
        sorting: false,
        paging: false,
        bPaginate: false,
        info: false,
        ajax: {
            url: matomo+"index.php?module=API&method=UserCountry.getCity&idSite="+siteId+"&period=range&date=2018-01-01,now&format=JSON&segment=pageUrl=="+encodeOnce(pageURL)+"&filter_limit=10",
            dataSrc: ""
        },
        columns: [
            {data: "label"},
            // { data: "country" },
            {data: "nb_visits"}
            // { data: "nb_actions" }
        ],
        columnDefs: [
            {
                className: "text-right",
                targets: [1]
            }
        ]
    });
}

function bindDownloadsChart() {
    $.ajax({
        url: matomo+"index.php?module=API&method=Actions.getDownloads&idSite="+siteId+"&period=month&date=last6&format=JSON&token_auth=anonymous&segment=actionUrl%3D@"+encodeTwice(actionURL),
        success: function (result) {
            var labelsD = Object.keys(result);
            var dataD = [];
            // console.log(result);
            for (var i in result) {
                if (result[i].length > 0) {
                    dataD.push(result[i][0].nb_visits);
                } else {
                    dataD.push(0);
                }
            }

            var ctx = document.getElementById("downloadsChart").getContext("2d");
            var chart = new Chart(ctx, {
                // The type of chart we want to create
                type: "line",

                // The data for our dataset
                data: {
                    labels: labelsD,
                    datasets: [
                        {
                            label: "Downloads",
                            borderColor: "#13294b",
                            data: dataD
                        }
                    ]
                },
                options: {
                    elements: {
                        line: {
                            tension: 0
                        }
                    },
                    legend: {
                        display: true
                    }
                }
            });
        }
    });
}

function bindVisitorsChart() {
    $.ajax({
        url: matomo+"index.php?module=API&method=VisitsSummary.getVisits&idSite="+siteId+"&period=month&date=last6&format=JSON&token_auth=anonymous&segment=pageUrl=="+encodeOnce(pageURL),
        success: function (result) {
            var labelsV = Object.keys(result);
            var dataV = Object.values(result);

            var ctx = document.getElementById("visitorsChart").getContext("2d");
            var chart = new Chart(ctx, {
                // The type of chart we want to create
                type: "line",

                // The data for our dataset
                data: {
                    labels: labelsV,
                    datasets: [
                        {
                            label: "Visitors",
                            borderColor: "#279989",
                            data: dataV
                        }
                    ]
                },
                options: {
                    elements: {
                        line: {
                            tension: 0
                        }
                    },
                    legend: {
                        display: true
                    }
                }
            });
        }
    });
}

async function barChartData() {
    var visits = {} ;
    await $.post(matomo+"index.php?module=API&method=VisitsSummary.getVisits&idSite=1&period=range&date=2018-01-01,now&format=JSON&token_auth=anonymous&segment=pageUrl=="+encodeOnce(pageURL),
        "",
        function (data,status) {
            visits= data;

        });
    $.ajax({
        url: matomo+"index.php?module=API&method=Actions.getDownloads&idSite="+siteId+"&period=range&date=2018-01-01,now&format=JSON&token_auth=anonymous&segment=actionUrl%3D@"+encodeTwice(actionURL),
        success: function (result) {
            var downloads = [];
            downloads.push(result[0].nb_visits);
            var ctx = document.getElementById("chart-area").getContext("2d");
            var config = {
                type: "doughnut",
                data: {
                    datasets: [
                        {
                            data: [downloads[0], visits.value],
                            backgroundColor: ["#279989", "#13294b"],
                            label: "Visits vs Downloads"
                        }
                    ],
                    labels: ["Downloads", "Visits"]
                },
                options: {
                    responsive: true,

                    legend: {
                        position: "top"
                    },
                    title: {
                        display: true
                        // text: "Visits vs Downloads"
                    },
                    animation: {
                        animateScale: true,
                        animateRotate: true
                    },

                    rotation: 1 * Math.PI,
                    circumference: 1 * Math.PI
                }
            };

            new Chart(ctx, config);
        }
    });
}


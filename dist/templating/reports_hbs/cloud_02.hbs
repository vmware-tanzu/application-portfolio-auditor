const dataUri = "data:text/plain;base64," + btoa(longText);

// Potentially displayed columns
const toolColumns = ['WINDUP', 'WAMT', 'CSA']

const maxValues = {}
const logScales = {}
const colorScales = {}

// Add thousands separator dots on tooltips.
function numberWithDots(x) {
    return x ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") : "";
}

// Compute max value for one simple column
function maxValueSimpleColumn(data, dataColumn) {
  return Math.max(1, d3.max(data, function(data) { return +data[dataColumn]; } ));
}

// Compute max values for each column
function computeMaxValues(data) {
  var columns=data.columns
  var indexWINDUP = 0
  var indexWAMT = 0
  for (i = 1; i < columns.length; ++i) {
    if(columns[i].startsWith('WINDUP')) { indexWINDUP=i; }
    if(columns[i].startsWith('WAMT criticals')) { indexWAMT=i; }
  }
  if(indexWINDUP!=0) {
    maxValues['WINDUP'] = maxValueSimpleColumn(data, 'WINDUP story points');
  }
  if(indexWAMT!=0) {
    maxValues['WAMT'] = maxValueSimpleColumn(data, 'WAMT total');
  }
}

// Get color
function getColor(d, toolColumn) {
  return d ? ( logScales[toolColumn](maxValues[toolColumn]) > 1.5*logScales[toolColumn](d.value) ? "#212529" : "white") : "#212529";
}

// Draw table
function drawTable(data) {

  // Logarithmic color scale - https://bl.ocks.org/jonsadka/5054e6a53e25a7582d4d73d3958fbbf9
  for(toolColumn of toolColumns) {
    logScales[toolColumn] = d3.scaleSymlog().domain([0, maxValues[toolColumn]])
  }

  colorScales['WINDUP'] = d3.scaleSequential((c) => d3.interpolateBlues(logScales['WINDUP'](c)))
  colorScales['WAMT'] = d3.scaleSequential((c) => d3.interpolateBlues(logScales['WAMT'](c)))
  colorScales['CSA'] = d3.scaleSequential((c) => d3.interpolateBlues(logScales['CSA'](c)))

  var sortAscending = true;
  var table = d3.select('#page-wrap').append('table');
  var titles = Object.keys(data[0]);
  var headers = table.append('thead').append('tr')
    .selectAll('th')
    .data(titles).enter()
    .append('th')
    .text(function(d) {
      return d
    })
    .on('click', function(d) {
      headers.attr('class', 'header');
      var de=d.srcElement.innerText
      if (de == "Applications" || de == "") { //these keys sort alphabetically - empty = Language column
        // sorting alphabetically");
        if (sortAscending) {
          rows.sort(function(a, b) {
            return d3.ascending(a[de], b[de]);
          });
          sortAscending = false;
          this.className = 'aes';
        } else {
          rows.sort(function(a, b) {
            return d3.descending(a[de], b[de]);
          });
          sortAscending = true;
          this.className = 'des';
        }
      } else {
        if (sortAscending) {
          //all other keys sort numerically including time
          rows.sort(function(a, b) {
            aval=(a[de].startsWith('n') ? -1 : a[de])
            bval=(b[de].startsWith('n') ? -1 : b[de])
            return bval - aval;
          });
          sortAscending = false;
          this.className = 'aes';
        } else {
          rows.sort(function(a, b) {
            aval=(a[de].startsWith('n') ? -1 : a[de])
            bval=(b[de].startsWith('n') ? -1 : b[de])
            return aval-bval;
          });
          sortAscending = true;
          this.className = 'des';
        }
      }
    });

  var rows = table.append('tbody').selectAll('tr')
                .data(data).enter()
                .append('tr');
  rows.selectAll('td')
    .data(function (d) {
      return titles.map(function (k) {
        return { 'value': d[k], 'name': k, 'app': d['Applications']};
      });
    }).enter()
    .append('td')
    .style('text-align',function(d) {
      return isNaN(d.value) ? (d.value ? (d.value.startsWith('n/a') ? 'center' : 'left' ) : 'center') : 'right';
    })
    .style("background-color", function(d) {
      if (!d || !d.name) { return "white"; }
      if (d.name.startsWith("Applications")) { return ""; }
      if (isNaN(d.value)) { return "white";}
      if (d.name.startsWith("CSA")) { return colorScales['CSA'](maxValues['CSA']-d.value); }
      if (d.name.startsWith("WAMT")) { return colorScales['WAMT'](d.value); }
      return colorScales['WINDUP'](d.value);
    })
    .style("color", function(d) {
      if (isNaN(d.value)) {
        return "#212529";
      } else if (d.name.startsWith("WINDUP")) {
        return getColor(d,'WINDUP');
      } else if (d.name.startsWith("WAMT")) {
        return getColor(d,'WAMT');
      } else if (d.name.startsWith("CSA")) {
        return d ? ( maxValues['CSA']*0.6 < d.value ? "#212529" : "white") : "#212529";
      } else {
        return "#212529";
      }
    })
    .attr('data-th', function (d) {
      return d.name;
    })
    .attr('class', 'click')
    .attr('data-href', function (d) {
      if (isNaN(d.value)) {
        return '';
      } else if (d.name.includes("Applications")) {
        return '';
      } else if (d.name.includes("CSA")) {
        return "{{CSA_URL}}#/application?app="+d.app;
      } else if (d.name.includes("WINDUP")) {
        return "./03__WINDUP/reports/"+reportMap.get(d.app);
      } else if (d.name.includes("WAMT")) {
        return "./04__WAMT/"+d.app+".html";
      } else {
        return '';
      }
    })
    .text(function (d) {
      return numberWithDots(d.value);
    });
}

function addCellLinks() {
  $(".click").click(function() {
      link=$(this).data("href")
      if(link) {
        window.open(link);
      }
  });
}

function addLanguageIcons() {
  $("td[data-th='Language']:contains('JavaScript')").html('<img src="./static/img/icon-javascript.svg" height="25" width="25" alt="JavaScript" title="JavaScript"></img>').addClass("text-center");
  $("td[data-th='Language']:contains('Java')").html('<img src="./static/img/icon-java.svg" height="25" width="25" alt="Java" title="Java"></img>').addClass("text-center");
  $("td[data-th='Language']:contains('Python')").html('<img src="./static/img/icon-python.svg" height="25" width="25" alt="Python" title="Python"></img>').addClass("text-center");
  $("td[data-th='Language']:contains('C#')").html('<img src="./static/img/icon-csharp.svg" height="25" width="25" alt="C#" title="C#"></img>').addClass("text-center");
  $("td[data-th='Language']:contains('Other')").html('<img src="./static/img/icon-other.svg" height="25" width="25" alt="Other" title="Other"></img>').addClass("text-center");
  $('th:contains("Language")').html('<i class="bi bi-translate" title="Languages" style="font-size: 20px"></i>').addClass("text-center");
}

// Start > 0 to avoid black numbers
for(toolColumn of toolColumns) {
  maxValues[toolColumn] = 1
}
maxValues['CSA'] = 10

d3.csv(dataUri)
  .then(function(data){
    computeMaxValues(data);
    drawTable(data);
    addCellLinks();
    addLanguageIcons()})
  .catch(function(error){throw error;})

// Collapsing panels
$('.collapse').on('show.bs.collapse', function () { $(this).siblings('.panel-heading').addClass('active');});
$('.collapse').on('hide.bs.collapse', function () { $(this).siblings('.panel-heading').removeClass('active');});
</script>
</body>
</html>

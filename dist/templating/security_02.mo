const dataUri = "data:text/plain;base64," + btoa(longText);

// Potentially displayed columns
const toolColumns = ['OWASPVulns', 'OWASPVulnLibs', 'FSBBugs', 'FSBTotalBugs', 'SLScanVulns', 'InsiderVulns', 'GrypeVulns', 'TrivyVulns']

const maxValues = {}
const logScales = {}
const colorScales = {}
const hasColumn = {}

// Add thousands separator dots on tooltips.
function numberWithDots(x) {
    return x ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") : "";
}

// Compute max value for one simple column
function maxValueSimpleColumn(data, dataColumn) {
  return Math.max(1, d3.max(data, function(data) { return +data[dataColumn]; } ));
}

// Compute max value for one simple column
function computeMaxValueSimpleColumn(data, maxColumn, dataColumn) {
  if(hasColumn[maxColumn]) {
    maxValues[maxColumn] = maxValueSimpleColumn(data,dataColumn);
  }
}

// Compute max values for each column
function computeMaxValues(data) {
  var columns=data.columns
  for(toolColumn of toolColumns) {
    hasColumn[toolColumn] = false
  }
  for (i = 1; i < columns.length; ++i) {
    if(columns[i].startsWith('OWASP')) { hasColumn['OWASPVulns'] = true; hasColumn['OWASPVulnLibs'] = true; }
    if(columns[i].startsWith('FSB')) { hasColumn['FSBBugs'] = true; hasColumn['FSBTotalBugs'] = true; }
    if(columns[i].startsWith('SLScan')) { hasColumn['SLScanVulns'] = true; }
    if(columns[i].startsWith('Insider')) { hasColumn['InsiderVulns'] = true; }
    if(columns[i].startsWith('Grype')) { hasColumn['GrypeVulns'] = true; }
    if(columns[i].startsWith('Trivy')) { hasColumn['TrivyVulns'] = true; }
  }

  if(hasColumn['OWASPVulns']) {
    low = maxValueSimpleColumn(data,'OWASP Low vulns');
    medium = maxValueSimpleColumn(data,'OWASP Medium vulns');
    high = maxValueSimpleColumn(data,'OWASP High vulns');
    critical = maxValueSimpleColumn(data,'OWASP Critical vulns');
    maxValues['OWASPVulns'] = Math.max(low,medium,high,critical,1);
  }

  if(hasColumn['FSBBugs']) {
    low = maxValueSimpleColumn(data,'FSB Low Bugs');
    medium = maxValueSimpleColumn(data,'FSB Medium Bugs');
    high = maxValueSimpleColumn(data,'FSB High Bugs');
    maxValues['FSBBugs'] = Math.max(low,medium,high,1);
  }

  computeMaxValueSimpleColumn(data, 'OWASPVulnLibs', 'OWASP Total vuln libs')
  computeMaxValueSimpleColumn(data, 'FSBTotalBugs', 'FSB Total Bugs')
  computeMaxValueSimpleColumn(data, 'SLScanVulns', 'SLScan SAST vulns')
  computeMaxValueSimpleColumn(data, 'InsiderVulns', 'Insider SAST vulns')
  computeMaxValueSimpleColumn(data, 'GrypeVulns', 'Grype vulns')
  computeMaxValueSimpleColumn(data, 'TrivyVulns', 'Trivy vulns')
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

  // This assignement does not work over a loop. Otherwise the obtained RGB values are different.
  colorScales['OWASPVulns'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['OWASPVulns'](c)) )
  colorScales['OWASPVulnLibs'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['OWASPVulnLibs'](c)) )
  colorScales['FSBBugs'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['FSBBugs'](c)) )
  colorScales['FSBTotalBugs'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['FSBTotalBugs'](c)) )
  colorScales['SLScanVulns'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['SLScanVulns'](c)) )
  colorScales['InsiderVulns'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['InsiderVulns'](c)) )
  colorScales['GrypeVulns'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['GrypeVulns'](c)) )
  colorScales['TrivyVulns'] = d3.scaleSequential( (c) => d3.interpolateYlOrRd(logScales['TrivyVulns'](c)) )

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
      if (d.name.startsWith("OWASP Total vuln libs")) { return colorScales['OWASPVulnLibs'](d.value); }
      if (d.name.startsWith("OWASP")) { return colorScales['OWASPVulns'](d.value); }
      if (d.name.startsWith("FSB Total Bugs")) { return colorScales['FSBTotalBugs'](d.value); }
      if (d.name.startsWith("FSB")) { return colorScales['FSBBugs'](d.value); }
      if (d.name.startsWith("SLScan")) { return colorScales['SLScanVulns'](d.value); }
      if (d.name.startsWith("Insider")) { return colorScales['InsiderVulns'](d.value); }
      if (d.name.startsWith("Grype")) { return colorScales['GrypeVulns'](d.value); }
      if (d.name.startsWith("Trivy")) { return colorScales['TrivyVulns'](d.value); }
      return "";
    })
    .style("color", function(d) {
      if (isNaN(d.value)) {
        return "#212529"; 
      } else if (d.name.startsWith("OWASP Total vuln libs")) {
        return getColor(d,'OWASPVulnLibs');
      } else if (d.name.startsWith("OWASP")) {
        return getColor(d,'OWASPVulns');
      } else if (d.name.startsWith("FSB Total Bugs")) {
        return getColor(d,'FSBTotalBugs');
      } else if (d.name.startsWith("FSB")) {
        return getColor(d,'FSBBugs');
      } else if (d.name.startsWith("SLScan")) {
        return getColor(d,'SLScanVulns');
      } else if (d.name.startsWith("Insider")) {
        return getColor(d,'InsiderVulns');
      } else if (d.name.startsWith("Grype")) {
        return getColor(d,'GrypeVulns');
      } else if (d.name.startsWith("Trivy")) {
        return getColor(d,'TrivyVulns');
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
      } else if (d.name.includes("OWASP")) {
        return "./05__OWASP_DC__{{APP_GROUP}}/"+d.app+"_dc_report.html";
      } else if (d.name.includes("FSB")) {
        return "./09__FindSecBugs/{{APP_GROUP}}__"+d.app+".html";
      } else if (d.name.includes("SLScan")) {
        return "./11__SLSCAN__{{APP_GROUP}}/"+d.app+".html";
      } else if (d.name.includes("Insider")) {
        return "./12__INSIDER__{{APP_GROUP}}/"+d.app+"_report.html";
      } else if (d.name.includes("Grype")) {
        return "./13__GRYPE__{{APP_GROUP}}/"+d.app+".html";
      } else if (d.name.includes("Trivy")) {
        return "./14__TRIVY__{{APP_GROUP}}/"+d.app+".html";
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

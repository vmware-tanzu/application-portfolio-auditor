const dataUri = "data:text/plain;base64," + btoa(longText);

// Used to add thousands separator dots on tooltips.
function numberWithDots(x) {
    return x ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") : "";
}

// Start > 0 to avoid black numbers
var maxValueArcheo = 1
var maxValuePMD = 1
var maxValueCPDFragments = 1
var maxValueCPDLines = 1
var maxValueCPDTokens = 1
var maxValueScancodeL = 1
var maxValueScancodeC = 1
var maxValueMAITags = 1

// Compute max value for one simple column
function maxValueSimpleColumn(data, dataColumn) {
  return Math.max(1, d3.max(data, function(data) { return +data[dataColumn]; } ));
}

// Compute max values for each column
function computeMaxValues(data) {
  var columns=data.columns
  var indexPMD = 0
  var indexScancode = 0
  var indexMAI = 0
  var indexArcheo = 0

  for (i = 1; i < columns.length; ++i) {
    if(columns[i].startsWith('PMD rules')) { indexPMD=i; }
    if(columns[i].startsWith('ScanCode')) { indexScancode=i; }
    if(columns[i].startsWith('MAI')) { indexMAI=i; }
    if(columns[i].startsWith('Archeo')) { indexArcheo=i; }
  }
  if(indexPMD!=0) {
    maxValuePMD = maxValueSimpleColumn(data,'PMD violations');
    maxValueCPDFragments = maxValueSimpleColumn(data,'Copy-pasted fragments');
    maxValueCPDLines = maxValueSimpleColumn(data,'Copy-pasted lines');
    maxValueCPDTokens = maxValueSimpleColumn(data,'Copy-pasted tokens');
  }
  if(indexScancode!=0) {
    maxValueScancodeL = maxValueSimpleColumn(data,'ScanCode Licenses');
    maxValueScancodeC = maxValueSimpleColumn(data,'ScanCode Copyrights');
  }
  if(indexMAI!=0) {
    maxValueMAITags = maxValueSimpleColumn(data,'MAI unique tags');
  }
  if(indexArcheo!=0) {
    maxValueArcheo = maxValueSimpleColumn(data,'Archeo Findings');
  }

}

function drawTable(data) {

  // Logarithmic color scale - https://bl.ocks.org/jonsadka/5054e6a53e25a7582d4d73d3958fbbf9
  const logScaleArcheo = d3.scaleSymlog().domain([0, maxValueArcheo])
  const colorScaleArcheo = d3.scaleSequential((c) => d3.interpolateGreens(logScaleArcheo(c)))

  const logScalePMD = d3.scaleSymlog().domain([0, maxValuePMD])
  const colorScalePMD = d3.scaleSequential((c) => d3.interpolateGreens(logScalePMD(c)))

  const logScaleCPDFragments = d3.scaleSymlog().domain([0, maxValueCPDFragments])
  const colorScaleCPDFragments = d3.scaleSequential((c) => d3.interpolateGreens(logScaleCPDFragments(c)))

  const logScaleCPDLines = d3.scaleSymlog().domain([0, maxValueCPDLines])
  const colorScaleCPDLines = d3.scaleSequential((c) => d3.interpolateGreens(logScaleCPDLines(c)))

  const logScaleCPDTokens = d3.scaleSymlog().domain([0, maxValueCPDTokens])
  const colorScaleCPDTokens = d3.scaleSequential((c) => d3.interpolateGreens(logScaleCPDTokens(c)))

  const logScaleScancodeL = d3.scaleSymlog().domain([0, maxValueScancodeL])
  const colorScaleScancodeL = d3.scaleSequential((c) => d3.interpolateGreens(logScaleScancodeL(c)))

  const logScaleScancodeC = d3.scaleSymlog().domain([0, maxValueScancodeC])
  const colorScaleScancodeC = d3.scaleSequential((c) => d3.interpolateGreens(logScaleScancodeC(c)))

  const logScaleMAITags = d3.scaleSymlog().domain([0, maxValueMAITags])
  const colorScaleMAITags = d3.scaleSequential((c) => d3.interpolateGreens(logScaleMAITags(c)))

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
      if (isNaN(d.value)){
        if (d) {
          if (d.name) {
            if( d.name.startsWith("Language") ) {
              return "white"
            } else if(d.value) {
              return d.value.startsWith('n/a') ? "white" : "";
            } else { return "" }
          } else { return "" }
        } else { return "" }
      } else {
        if (d.name.startsWith("Archeo")) {
          return d ? colorScaleArcheo(d.value) : "";
        } else if (d.name.startsWith("PMD")) {
          return d ? colorScalePMD(d.value) : "";
        } else if (d.name.startsWith("Copy-pasted fragments")) {
          return d ? colorScaleCPDFragments(d.value) : "";
        } else if (d.name.startsWith("Copy-pasted lines")) {
          return d ? colorScaleCPDLines(d.value) : "";
        } else if (d.name.startsWith("Copy-pasted tokens")) {
          return d ? colorScaleCPDTokens(d.value) : "";
        } else if (d.name.startsWith("ScanCode Licenses")) {
          return d ? colorScaleScancodeL(d.value) : "";
        } else if (d.name.startsWith("ScanCode Copyrights")) {
          return d ? colorScaleScancodeC(d.value) : "";
        } else if (d.name.startsWith("MAI")) {
          return d ? colorScaleMAITags(d.value) : "";
        } else {
          return "";
        }
      }
    })
    .style("color", function(d) {
      if (isNaN(d.value)) {
        return "#212529";
      } else if (d.name.startsWith("Archeo")) {
        return d ? ( logScaleArcheo(maxValueArcheo) > 1.5*logScaleArcheo(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("PMD")) {
        return d ? ( logScalePMD(maxValuePMD) > 1.5*logScalePMD(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("Copy-pasted fragments")) {
        return d ? ( logScaleCPDFragments(maxValueCPDFragments) > 1.5*logScaleCPDFragments(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("Copy-pasted lines")) {
        return d ? ( logScaleCPDLines(maxValueCPDLines) > 1.5*logScaleCPDLines(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("Copy-pasted tokens")) {
        return d ? ( logScaleCPDTokens(maxValueCPDTokens) > 1.5*logScaleCPDTokens(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("ScanCode Licenses")) {
        return d ? ( logScaleScancodeL(maxValueScancodeL) > 1.5*logScaleScancodeL(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("ScanCode Copyrights")) {
        return d ? ( logScaleScancodeC(maxValueScancodeC) > 1.5*logScaleScancodeC(d.value) ? "#212529" : "white") : "#212529";
      } else if (d.name.startsWith("MAI")) {
        return d ? ( logScaleMAITags(maxValueMAITags) > 1.5*logScaleMAITags(d.value) ? "#212529" : "white") : "#212529";
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
      } else if (d.name.includes("Archeo")) {
        return "./16__ARCHEO/"+d.app+".html";
      } else if (d.name.includes("PMD")) {
        return "./07__PMD/pmd/{{APP_GROUP}}__"+d.app+"_pmd.html";
      } else if (d.name.includes("Copy-pasted")) {
        return "./07__PMD/cpd/{{APP_GROUP}}__"+d.app+"__cpd.xml";
      } else if (d.name.includes("ScanCode")) {
        return "./06__SCANCODE__{{APP_GROUP}}/"+d.app+"/index.html";
      } else if (d.name.includes("MAI")) {
        return "./10__MAI/mai__{{APP_GROUP}}__"+d.app+".html";
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

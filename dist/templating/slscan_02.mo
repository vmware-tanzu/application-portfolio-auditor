    const dataUri = "data:text/plain;base64," + btoa(unescape(encodeURIComponent(longText)));
    
    var maxValue = 1
    var logScaleVulns
    var colorScaleVulns

    // Used to add thousands separator dots on tooltips.
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
      critical = maxValueSimpleColumn(data, 'Critical');
      high = maxValueSimpleColumn(data, 'High');
      medium = maxValueSimpleColumn(data, 'Medium');
      low = maxValueSimpleColumn(data, 'Low');
      // Start > 0 to avoid black numbers
      maxValue = Math.max(1,critical,high,medium,low);
    }

    // Get color
    function getColor(d) {
      return d ? ( logScaleVulns(maxValue) > 1.5*logScaleVulns(d.value) ? "#212529" : "white") : "#212529";
    }

    // Draw table
    function drawTable(data) {
    
      // Logarithmic color scale - https://bl.ocks.org/jonsadka/5054e6a53e25a7582d4d73d3958fbbf9
      logScaleVulns = d3.scaleSymlog().domain([0, maxValue])
      colorScaleVulns = d3.scaleSequential((c) => d3.interpolateYlOrRd(logScaleVulns(c)))
    
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
          if (de == "Tool" || de == "Status") { //these keys sort alphabetically
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
    
      var latestDataHref=''
      var rows = table.append('tbody').selectAll('tr')
                    .data(data).enter()
                    .append('tr');
      rows.selectAll('td')
        .data(function (d) {
          return titles.map(function (k) {
            return { 'value': d[k], 'name': k, 'tool': d['Tool']};
          });
        }).enter()
        .append('td')
        .style('text-align',function(d) {
          return isNaN(d.value) ? (d.value ? (d.value.length==1 ? 'center' : 'left' ) : 'center') : 'right';
        })
        .style("background-color", function(d) {
          if (isNaN(d.value) || !d || !d.name) {
            return "white";
          }
          if (d.name.startsWith("Critical") || d.name.startsWith("High") || d.name.startsWith("Medium") || d.name.startsWith("Low")) {
            return colorScaleVulns(d.value);
          } else {
            return "";
          }
        })
        .style("color", function(d) {
          if (isNaN(d.value)) {
            return "#212529"; 
          } else if (d.name.startsWith("Critical") || d.name.startsWith("High") || d.name.startsWith("Medium") || d.name.startsWith("Low")) {
            return getColor(d);
          } else {
            return "#212529";
          }
        })
        .attr('data-th', function (d) {
          return d.name;
        })
        .attr('class', 'click')
        .attr('data-href', function (d) {
          if (d.value.startsWith("Shell Script Analysis")) {
            latestDataHref="./"+app_name+"/bash-report.html"

          } else if (d.value.startsWith("Class File Analyzer")) {
            latestDataHref="./"+app_name+"/class-report.html";

          } else if (d.value.startsWith("Security Audit for Infrastructure")) {
            latestDataHref="./"+app_name+"/source-yaml-report.html";

          } else if (d.value.startsWith("Secrets Audit")) {
            latestDataHref="./"+app_name+"/credscan-report.html";

          } else if (d.value.startsWith("Java Source Analyzer")) {
            latestDataHref="./"+app_name+"/source-java-report.html";

          } else if (d.value.startsWith("PHP Security Audit")) {
            latestDataHref="./"+app_name+"/audit-php-report.html";

          } else if (d.value.startsWith("PHP Security Analysis")) {
            latestDataHref="./"+app_name+"/taint-php-report.html";

          } else if (d.value.startsWith("Dependency Scan (nodejs)")) {
            latestDataHref="./"+app_name+"/depscan-report-nodejs.html";

          } else if (d.value.startsWith("Dependency Scan (universal)")) {
            latestDataHref="./"+app_name+"/depscan-report-universal.html";

          } else if (d.value.startsWith("JSP Security Audit")) {
            latestDataHref="./"+app_name+"/audit-jsp-report.html";

          } else if (d.value.startsWith("JSP Source Analyzer")) {
            latestDataHref="./"+app_name+"/source-jsp-report.html";

          } else if (d.value.startsWith("Python Source Analyzer")) {
            latestDataHref="./"+app_name+"/source-python-report.html";

          } else if (d.value.startsWith("SQL Source Analyzer")) {
            latestDataHref="./"+app_name+"/source-sql-report.html";
          }
          return latestDataHref;
        })
        .text(function (d) {
          return numberWithDots(d.value);
        });
    }
    
    function addCellLinks() {
      $(".click").click(function() {
          link=$(this).data("href")
          if(link) {
            document.getElementById('iframeReport').src=link;
          }
      });
    }

    d3.csv(dataUri)
  .then(function(data){
    computeMaxValues(data);
    drawTable(data);
    addCellLinks();})
  .catch(function(error){throw error;})
    </script>
</body>
</html>
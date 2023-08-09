    const dataUri = "data:text/plain;base64," + btoa(unescape(encodeURIComponent(longText)));
    
  // Draw table
  function drawTable(data) {
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
        });
      var rows = table.append('tbody').selectAll('tr').data(data).enter().append('tr');
      rows.selectAll('td')
        .data(function (d) {
          return titles.map(function (k) {
            return { 'value': d[k], 'name': k};
          });
        }).enter()
        .append('td')
        .style('text-align',function(d) {
          if (!d || !d.name || !d.name.startsWith("Description")) return 'center';
          return 'left';
        })
        .style("background-color", function(d) {
          if (!d || !d.name || !d.name.startsWith("Severity")) return "";
          switch (d.value) {
            case "Critical": return "#e40000";
            case "High": return "#ff8800";
            case "Medium": return "#e9c600";
            case "Low": return "#5fbb31";
            case "Unknown": return "#747474";
            default: return "";
          }
        })
        .html(function (d) {
          return d.value;
        });
    };
  
    d3.csv(dataUri)
    .then(function(data){drawTable(data);})
    .catch(function(error){throw error;})
  </script>
</body>
</html>
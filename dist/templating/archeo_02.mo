    const dataUri = "data:text/plain;base64," + btoa(unescape(encodeURIComponent(longText)));

    var colorFindingPurple = getComputedStyle(document.documentElement).getPropertyValue('--findingPurple');
    var colorFindingRed = getComputedStyle(document.documentElement).getPropertyValue('--findingRed');
    var colorFindingOrange = getComputedStyle(document.documentElement).getPropertyValue('--findingOrange');
    var colorFindingYellow = getComputedStyle(document.documentElement).getPropertyValue('--findingYellow');
    var colorFindingGreen = getComputedStyle(document.documentElement).getPropertyValue('--findingGreen');
    var colorTextNormal = getComputedStyle(document.documentElement).getPropertyValue('--bs-body-color');
    var colorTextWhite = '#ffffff';

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
          if (!d || !d.name || !d.name.startsWith("Description") && !d.name.startsWith("Library") ) return 'center';
          return 'left';
        })
        .style("background-color", function(d) {
          if (!d || !d.name || !d.name.startsWith("Severity")) return "";
          switch (d.value) {
            case "Critical": return colorFindingPurple;
            case "High": return colorFindingRed;
            case "Medium": return colorFindingOrange;
            case "Low": return colorFindingYellow;
            case "Info": return colorFindingGreen;
            default: return "";
          }
        })
        .style("color", function(d) {
          if (!d || !d.name || !d.name.startsWith("Severity")) return colorTextNormal;
          switch (d.value) {
            case "Critical": return colorTextWhite;
            case "High": return colorTextWhite;
            default: return colorTextNormal;
          }
        })
        .style("color", function(d) {
          if (!d || !d.name || !d.name.startsWith("Severity")) return "";
          switch (d.value) {
            case "Critical": return colorTextWhite;
            case "High": return colorTextWhite;
            default: return colorTextNormal;
          }
        })
        .html(function (d) {
          return d.value;
        });
    };
    
    d3.csv(dataUri)
    .then(function(data){drawTable(data);})
    .catch(function(error){throw error;})

    // Values of the support data graph
    const libs_total = {{ARCHEO__ALL_LIBS}}
    const libs_duplicated = {{ARCHEO__DUPLICATED_LIBS}}
    const libs_undesirable = {{ARCHEO__UNDESIRABLE_LIBS}}
    const libs_supported = {{ARCHEO__SUPPORTED_LIBS}}
    const libs_expiring_oss = {{ARCHEO__OSS_SUPPORT_ENDING_SOON_LIBS}}
    const libs_commercial_only = {{ARCHEO__ONLY_COMMERCIAL_SUPPORTED_LIBS}}
    const libs_unsupported = {{ARCHEO__UNSUPPORTED_LIBS}}
    const libs_unsupportable = {{ARCHEO__NON_SUPPORTABLE_LIBS}}

    // Dimensions and margins of the support data graph
    const support_data_viz_width = 680,
    support_data_viz_height = 450,
    support_data_viz_margin = 50;

    // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
    const radius = Math.min(support_data_viz_width, support_data_viz_height) / 2 - support_data_viz_margin
    const svg = d3.select("#support_data_viz")
      .append("svg")
        .attr("width", support_data_viz_width)
        .attr("height", support_data_viz_height)
      .append("g")
        .attr("transform", `translate(${support_data_viz_width/2},${support_data_viz_height/2})`);

    const support_data = [
      { id: 1, label: 'Supported', count: libs_supported, color: colorFindingGreen },
      { id: 2, label: 'Expiring OSS', count: libs_expiring_oss, color: colorFindingOrange },
      { id: 3, label: 'Commercial only', count: libs_commercial_only, color: colorFindingRed },
      { id: 4, label: 'Unsupported', count: libs_unsupported, color: colorFindingPurple },
      { id: 5, label: 'Other', count: libs_unsupportable, color: '#ccc' },
    ];

    // Compute the position of each group on the pie:
    const pie = d3.pie()
      .sort(null) // Do not sort group by size
      .value(d => d.count)
    const support_data_ready = pie(support_data)

    // The arc generator
    const arc = d3.arc()
      .innerRadius(radius * 0.5) // Size of the donut hole
      .outerRadius(radius * 0.8)

    // Another arc that won't be drawn. Just for labels positioning
    const outerArc = d3.arc()
      .innerRadius(radius * 0.9)
      .outerRadius(radius * 0.9)

    // Build the pie chart: Basically, each part of the pie is a path that we build using the arc function.
    svg
      .selectAll('allSlices')
      .data(support_data_ready.filter(d => d.data.count > 0))
      .join('path')
      .attr('d', arc)
      .attr('fill', d => d.data.color)
      .attr("stroke", "white")
      .style("stroke-width", "2px")
      .style("opacity", 1)

    // Add the polylines between chart and labels:
    svg
      .selectAll('allPolylines')
      .data(support_data_ready.filter(d => d.data.count > 0))
      .join('polyline')
        .attr("stroke", "black")
        .style("fill", "none")
        .attr("stroke-width", 1)
        .attr('points', function(d) {
          const posA = arc.centroid(d) // line insertion in the slice
          const posB = outerArc.centroid(d) // line break: we use the other arc generator that has been built only for that
          const posC = outerArc.centroid(d); // Label position = almost the same as posB
          const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2 // we need the angle to see if the X position will be at the extreme right or extreme left
          posC[0] = radius * 0.95 * (midangle < Math.PI ? 1 : -1); // multiply by 1 or -1 to put it on the right or on the left
          return [posA, posB, posC]
        })

    // Add the text for the polylines:
    svg
      .selectAll('allLabels')
      .data(support_data_ready.filter(d => d.data.count > 0))
      .join('text')
        .text(d => d.data.label+' ('+d.data.count+')')
        .attr('transform', function(d) {
            const pos = outerArc.centroid(d);
            const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2
            pos[0] = radius * 0.99 * (midangle < Math.PI ? 1 : -1);
            return `translate(${pos})`;
        })
        .style('text-anchor', function(d) {
            const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2
            return (midangle < Math.PI ? 'start' : 'end')
        })

    // Add HTML content using foreignObject
    const foreignObject = svg.append('foreignObject')
        .attr('x', -support_data_viz_width / 4) // Adjust position as needed
        .attr('y', -support_data_viz_height / 12) // Adjust position as needed
        .attr('width', support_data_viz_width / 2) // Adjust size as needed
        .attr('height', support_data_viz_height / 2 ); // Adjust size as needed

    foreignObject.append('xhtml:div')
       .html('<div style="text-align:center;color:black;font-size:16px;"><span style="font-size:30px;font-weight:bold;">'+(libs_commercial_only + libs_unsupported)+'&nbsp;</span>libraries<br/>without OSS support</div>');

  </script>
</body>
</html>
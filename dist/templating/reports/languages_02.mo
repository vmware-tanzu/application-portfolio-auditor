var colors = ["#0070ec", "#ff7f0e", "#03ab00", "#d62728", "#ffc700", "#9467bd", "#e377c2", "#17becf", "#89969f", "#1a98ff", "#fff0bc", "#b9ecac", "#a44200", "#1d7874", "#911eb4", "#46f0f0", "#f032e6", "#bcf60c", "#fabebe", "#9a6324", "#800000", "#ffd8b1", "#808080", "#e6194b", "#0ee000", "#4e0fef", "#f5f107", "#000000"];

var tooltip = d3.select("body")
	.append("div")
	.style("position", "absolute")
	.style("z-index", "10")
  .style("font-size","10pt")
	.style("visibility", "hidden");

// Functions that change the tooltip when user hover / move / leave a cell
var mouseover = function(d) {
  d3.select(this)
    .style("stroke", "grey")
    .style("opacity", 0.9)
  return tooltip.style("visibility", "visible");
}

var mouseout = function(d) {
  d3.select(this)
    .style("stroke", "none")
    .style("opacity", 1)
    return tooltip.style("visibility", "hidden");
}

// Calculates sum of all LoCs for each app.
var total = function(d, i, columns) {
  for (i = 1, t = 0; i < columns.length; ++i) t += d[columns[i]] = +d[columns[i]];
  d.total = t;
  return d;
}

// Used to add thousands separator dots on tooltips.
function numberWithDots(x) {
    return x ? x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".") : "";
}

var drawAll = function(isLogarithmic, isSortedByName, isSimpleList) {

  if(isSimpleList) {
    var longText = longTextLinguist;
  } else {
    var longText = longTextCloc;

  }
  var dataUri = "data:text/plain;base64," + btoa(longText);

  // Map containing the total LoCs for each langugage
  var sumKeys = {}

  // Initializes sumKeys to { 0, 0 , 0 ...}
  d3.csv(dataUri, function(d, i, columns){
    for (i = 1; i < columns.length; ++i) {
      sumKeys[columns[i]] = 0
    }
  },function(){});

  // Calculates sumKeys
  d3.csv(dataUri, function(d, i, columns){
    for (i = 1, t = 0; i < columns.length; ++i) {
      sumKeys[columns[i]] = Number(sumKeys[columns[i]]) + Number(d[columns[i]]);
    }
  },function(){});

  // Cleanup current drawing
  d3.selectAll("svg > *").remove();

  // Create a new one
  var svg = d3.select("svg"),
    margin = {top: 40, right: 20, bottom: 40, left: 340},
    width = +svg.attr("width") - margin.left - margin.right,
    height = +svg.attr("height") - margin.top - margin.bottom,
    g = svg.append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  if(isLogarithmic)
    // Log
    var x = d3.scaleLog().range([0, width]).clamp(true);
  else
    // Linear
    var x = d3.scaleLinear().rangeRound([0, width]);

  var y = d3.scaleBand().rangeRound([0, height]).paddingInner(0.1).align(0.1);

  var draw = function(error, data) {
    if (error) throw error;

    var keys = data.columns.slice(1);
    keys.sort(function(a, b) { 
      // Sort languages alphabetically
      // return b.total-a.total;
      // Sort languages starting with the ones having the lowest total LoCs
      return Number(sumKeys[a])-Number(sumKeys[b]);
    });

    if (isSortedByName)
      data.reverse();
    else
      data.sort(function(a, b) { return b.total - a.total; });

    usedColors=colors.slice(0,keys.length).reverse();
    var z = d3.scaleOrdinal().range(usedColors);

    x.domain([1, d3.max(data, function(d) { return d.total; })]).nice();
    y.domain(data.map(function(d) { return d.App; }));
    z.domain(keys);
    
    g.append("g")
      .selectAll("g")
      .data(d3.stack().keys(keys)(data))
      .enter().append("g")
        .attr("fill", function(d) { return z(d.key); })
      .selectAll("rect")
      .data(function(d) { return d; })
      .enter().append("rect")
        .attr("y", function(d) { return y(d.data.App); })
        .attr("x", function(d) { return x(d[0]); })
        .attr("width", function(d) { return x(d[1]) - x(d[0]); })	
        .attr("height", y.bandwidth())	
        .on("mouseover", mouseover)
        .on("mousemove", function(d) {
            var i = usedColors.indexOf(this.parentNode.getAttribute("fill"));
            tooltip.html("<b>"+keys[i]+"</b>: "+numberWithDots(d[1]-d[0])+" lines");
            return tooltip.style("top", (event.pageY-5)+"px").style("left",(event.pageX+20)+"px");
        })
        .on("mouseout", mouseout);

    g.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(0,0)")
        .call(d3.axisLeft(y));

    // x axis (top)
    xAxisTop=g.append("g")
        .attr("class", "axis")
        // New line
        .attr("transform", "translate(0,"+(-10)+")")
    // Text for x-axis (top)
    xAxisTop.append("text")
        .attr("y", -15)
        .attr("x", x(x.ticks().pop()) -30)
        .attr("dy", "0.32em")
        .attr("fill", "#000")
        .attr("font-weight", "bold")
        .attr("text-anchor", "start")
        .text("Applications (LoC)")
        // New line
        .attr("transform", "translate("+ (-width -105 )+",5)");

    // // x axis (bottom)
    // xAxisBottom=g.append("g")
    //     .attr("class", "axis")
    //     // New line
    //     .attr("transform", "translate(0,"+(height+10)+")")
    // // Text for x-axis (bottom)
    // xAxisBottom.append("text")
    //     .attr("y", -15)
    //     .attr("x", x(x.ticks().pop()) + 0.5)
    //     .attr("dy", "0.32em")
    //     .attr("fill", "#000")
    //     .attr("font-weight", "bold")
    //     .attr("text-anchor", "start")
    //     .text("Lines of Code")
    //     // New line
    //     .attr("transform", "translate("+ (-width -105 )+",5)");

    if(isLogarithmic){ 
      xAxisTop.call(d3.axisTop(x).ticks(15, ",.1s"))
      // xAxisBottom.call(d3.axisTop(x).ticks(15, ",.1s"))
    } else {
      xAxisTop.call(d3.axisTop(x).ticks())
      // xAxisBottom.call(d3.axisTop(x).ticks())
    }

    // Legend
    var legend = g.append("g")
        .attr("font-family", "sans-serif")
        .attr("text-anchor", "end")
      .selectAll("g")
      .data(keys.slice().reverse())
      .enter().append("g")
      .attr("transform", function(d, i) { return "translate(-5," + (height/3 - 20 / 3 * keys.length -20 + i * 20) + ")"; });

    legend.append("rect")
        .attr("x", width - 18)
        .attr("y", 0)
        .attr("width", 18)
        .attr("height", 18)
        .attr("fill", z);

    legend.append("text")
        .attr("x", width - 24)
        .attr("y", 9.5)
        .attr("dy", "0.32em")
        .text(function(d) { return d; });
  }
  d3.csv(dataUri,total,draw);
}

var onchange = function() {
  drawAll($('#scaleSwitch').is(":checked"), $('#sortSwitch').is(":checked"), $('#simpleSwitch').is(":checked"))
}

$("#scaleSwitch").on('change', onchange);
$("#sortSwitch").on('change', onchange);
$("#simpleSwitch").on('change', onchange);

onchange()

// Collapsing panels
$('.collapse').on('show.bs.collapse', function () { $(this).siblings('.panel-heading').addClass('active');});
$('.collapse').on('hide.bs.collapse', function () { $(this).siblings('.panel-heading').removeClass('active');});

</script>

</body>
</html>

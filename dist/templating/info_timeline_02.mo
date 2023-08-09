
  ;
  function getDuration(date_start, date_end) {
    const hours = parseInt(Math.abs(date_end - date_start) / (1000 * 60 * 60) % 24);
    const minutes = parseInt(Math.abs(date_end.getTime() - date_start.getTime()) / (1000 * 60) % 60);
    const seconds = parseInt(Math.abs(date_end.getTime() - date_start.getTime()) / (1000) % 60); 
    return ((hours > 0 ) ? hours+"h ":"")+minutes+"mins "+seconds+"s"
  }

  TimelinesChart()(document.getElementById('timelines-chart'))
      .leftMargin(0)
      .rightMargin(200)
      .width(1200)
      .zScaleLabel('My Scale Units')
      .zQualitative(true)
      .segmentTooltipContent(function (d) {
        const date_start=d.timeRange[0]
        const date_end=d.timeRange[1]
        const duration = getDuration(date_start, date_end);
        return "<b>"+d.val+": </b>"+d.label+" ["+duration+"]<br/><b>From: </b>"+date_start.toLocaleString()+" <b>To: </b>"+date_end.toLocaleString();
      })
      .onSegmentClick(function (d) {
        url=d.data.url
        if (url) {
          window.open(url, '_blank').focus();
        }
      })
      .data(myData);
  </script>
  </body>
</html>
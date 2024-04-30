<!--
    Copyright 2019-2024 VMware, Inc.
    SPDX-License-Identifier: Apache-2.0
-->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <meta name="description" content="">
  <meta name="author" content="">
  <title>Security Report</title>
  <!-- Bootstrap core CSS -->
  <link href="./../static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="./../static/img/favicon.ico" rel="shortcut icon" type="image/x-icon"/>
  <link href="./../static/css/core.css" rel="stylesheet"/>
  <style>
    .bd-masthead { position: relative; padding: 3rem 15px; }
    div#tools.bd-masthead.py-3.mb-3 { padding-bottom: 0rem!important }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 0px auto;
    } 
  
    :root {
      --findingPurple: #a61c00;
      --findingRed: #cc0000;
      --findingOrange: #e69138;
      --findingYellow: #f1c232; 
      --findingGreen: #6aa84f;
    }
    
    span.badge.bg-dark, span.badge.bg-secondary, a.badge.bg-secondary, a.badge.bg-light.text-dark { vertical-align:middle; margin-top: -0.3em; }
    a.badge.bg-light.text-dark {text-decoration: none;}
  </style>
</head>

<body>
  <!-- Header -->
  <header class="navbar navbar-expand navbar-dark flex-column flex-md-row bd-navbar">
    <div class="container">
      <a class="navbar-brand mr-0 me-md-2" href="./../index.html"><img class="mr-3 me-3 filter-white company-icon" src="./../static/img/company-icon.svg" alt="Tanzu"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link" href="./../index.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./../cloud.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        <li class="nav-item"><a class="nav-link active" href="./../security.html">Security</a></li>
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./../quality.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
        {{#HAS_LANGUAGES_REPORT}}<li class="nav-item"><a class="nav-link" href="./../languages.html">Languages</a></li>{{/HAS_LANGUAGES_REPORT}}
        <li class="nav-item">
          <a class="nav-link" href="./../info.html"><i class="bi bi-speedometer"></i></a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="{{NAV_LINK}}" rel="noreferrer" target="_blank"><i class="{{NAV_ICON}}"></i></a>
        </li>
      </ul>
    </div>
  </header>

  <!-- Masthead -->
  <div class="bd-masthead py-1" id="content" role="main">
    <div class="container">
      <h1 class="display-4 mt-4 mb-2">Security reports</h1>
      <div>
        <p class="lead mb-3 text-black-50">Consolidated application security findings.</p>
      </div>
    </div>
  </div>

  <!-- Tools -->
  <div class="bd-masthead py-3 mb-3" id="tools" role="main">
    <div class="container">
      <div class="d-flex">
          <a href="./../12__INSIDER/" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./../static/img/insider.png" height="50" width="50" alt="Insider SAST"></a>
          <div>
            <h5 class="mt-0 mb-1">Insider SAST <a href="https://github.com/insidersec/insider" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{INSIDER_VERSION}}</a></h5>
            Identifies locally various kinds of security issues in application code. (<a href="./.{{INSIDER_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="./.{{INSIDER_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
          </div>
      </div>
    </div>
  </div>

  <div class="container">
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="./../security.html">Security</a></li>
        <li class="breadcrumb-item active">Insider SAST</li>
        <li class="breadcrumb-item">{{APP}}</li>
      </ol>
    </nav>
  </div>

  <div class="container">
    <div class="row justify-content-center">
      <div class="col-8">
        <div id="stats_viz"></div>
      </div>
      {{#HAS_ANOTHER_SECURITY_REPORT}}
      <div class="col-4">
        <div class="card mt-5 border-0">
          <div class="row gy-2">
            <div class="col-12">
              <div class="card border-0" style="background-color: #333333; color: #ffffff;">
                <div class="card-body" style="padding-bottom: 0px;">
                  <div class="row align-items-center">
                    <div class="col-3 mb-3">
                      <div class="d-flex align-items-center">
                        <div>
                          <h6 class="m-0">Linked reports</h6>
                        </div>
                      </div>
                    </div>
                    <div class="col-9">
                      <div class="row justify-content-end" style="margin-right: 0px; margin-left: 0px; ">
                        {{#HAS_ODC_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../05__OWASP_DC/{{APP}}.html"><img src="./../static/img/owasp.svg" height="50px" width="50px" alt="Open Web Application Security Project Dependency-Check"></a>
                          </div>
                        </div>
                        {{/HAS_ODC_REPORT}}
                        {{#HAS_FSB_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../09__FindSecBugs/{{APP}}.html"><img src="./../static/img/fsb.png" height="50px" width="50px" alt="Find Security Bugs"></a>
                          </div>  
                        </div>
                        {{/HAS_FSB_REPORT}}
                        {{#HAS_SLSCAN_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../11__SLSCAN/{{APP}}.html"><img src="./../static/img/scan-light.png" height="50px" width="50px" alt="ShiftLeft SAST Scan"></a>
                          </div>  
                        </div>
                        {{/HAS_SLSCAN_REPORT}}
                        {{#HAS_INSIDER_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px; opacity: 0.3;">
                            <a href="./../12__INSIDER/{{APP}}.html"><img src="./../static/img/insider.png" height="50px" width="50px" alt="Insider SAST"></a>
                          </div>  
                        </div>
                        {{/HAS_INSIDER_REPORT}}
                        {{#HAS_GRYPE_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../13__GRYPE/{{APP}}.html"><img src="./../static/img/grype.png" height="50px" width="50px" alt="Grype"></a>
                          </div>  
                        </div>
                        {{/HAS_GRYPE_REPORT}}
                        {{#HAS_TRIVY_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../14__TRIVY/{{APP}}.html"><img src="./../static/img/trivy.svg" height="50px" width="50px" alt="Trivy"></a>
                          </div>  
                        </div>
                        {{/HAS_TRIVY_REPORT}}
                        {{#HAS_OSV_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../15__OSV/{{APP}}.html"><img src="./../static/img/osv.png" height="50px" width="50px" alt="OSV"></a>
                          </div>  
                        </div>
                        {{/HAS_OSV_REPORT}}
                        {{#HAS_BEARER_REPORT}}
                        <div class="col-3 mb-3">
                          <div class="card text-center justify-content-center" style="width: 58px; height: 58px;">
                            <a href="./../17__BEARER/{{APP}}.html"><img src="./../static/img/bearer.png" height="50px" width="50px" alt="Bearer"></a>
                          </div>  
                        </div>
                        {{/HAS_BEARER_REPORT}}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      {{/HAS_ANOTHER_SECURITY_REPORT}}
    </div>
  </div>
  <!-- /.container -->
  
  <div class="container">
    <div class="ratio ratio-1x1">
      <iframe id="iframeReport" class="embed-responsive-item" src="./{{APP}}_report.html" allowfullscreen></iframe>
    </div>
  </div>
  <!-- /.container -->

  <div class="container">
    <div class="flex-column">
      <div id="page-wrap">
      </div>
    </div>
    <div class="row">
      <p></p>
    </div>
  </div>
  <!-- /.container -->

  <!-- Footer -->
  <section class="footer-component footer-container">
    <footer class="footer">
      <div class="row">
        <div class="col-lg-12 col-md-12 footer-links-wrapper">
          <div class="footer-links mt-3">
            <span class="mb-3">
              <a href="https://www.vmware.com/" rel="noreferrer" target="_blank"><img class="mr-3 me-2 company-logo" src="./../static/img/company.svg" alt="VMware"/></a>
              Generated with
              <a href="{{NAV_LINK}}" class="text-xxss text-black mb-3 ml-lg-3" rel="noreferrer" target="_blank">Application Portfolio Auditor</a>
              v.{{TOOL_VERSION}} from
              <a href="https://tanzu.vmware.com/labs" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Tanzu Labs" title="Tanzu Labs" rel="noreferrer" target="_blank">Tanzu Labs</a>
              on {{REPORT_TIMESTAMP}}</span>
          </div>
          <div class="footer-links mt-3">
              <span class="mb-3">&#169; 2024 Broadcom</span>
              <a href="https://www.vmware.com/help/legal.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Terms of Use" title="Terms of Use" name="nav_footer_bottom:Terms_of_Use" rel="noreferrer" target="_blank">Terms of Use</a> 
              <a href="https://www.vmware.com/help/privacy/california-privacy-rights.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Your California Privacy Rights" title="Your California Privacy Rights" name="nav_footer_bottom:Your_California_Privacy_Rights" rel="noreferrer" target="_blank">Your California Privacy Rights</a> 
              <a href="https://www.vmware.com/help/privacy.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Privacy" title="Privacy" name="nav_footer_bottom:Privacy" rel="noreferrer" target="_blank">Privacy</a> 
              <a href="https://www.vmware.com/help/accessibility.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Accessibility" title="Accessibility" name="nav_footer_bottom:Accessibility" rel="noreferrer" target="_blank">Accessibility</a> 
              <a href="https://www.vmware.com/help/trademarks.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Trademarks" title="Trademarks" name="nav_footer_bottom:Trademarks" rel="noreferrer" target="_blank">Trademarks</a> 
              <a href="https://www.vmware.com/topics/glossary.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Glossary" title="Glossary" name="nav_footer_bottom:Glossary" rel="noreferrer" target="_blank">Glossary</a> 
              <a href="https://www.vmware.com/help.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Help" title="Help" name="nav_footer_bottom:Help" rel="noreferrer" target="_blank">Help</a> 
          </div>
          <div class="footer-disclaimer mt-3">
            <span class="mb-3">This website does not use cookies or other tracking technology.</span>
          </div>
        </div>
      </div>
    </footer>
  </section>

  <!-- Bootstrap core JavaScript -->
  <script src="./../static/js/jquery-{{JQUERY_VERSION}}.min.js"></script>
  <script src="./../static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/js/bootstrap.bundle.min.js"></script>
  <script src="./../static/js/d3.v{{D3_VERSION}}.min.js"></script>
  <script>
    const app_name="{{APP}}"

    const colorFindingPurple = getComputedStyle(document.documentElement).getPropertyValue('--findingPurple');
    const colorFindingRed = getComputedStyle(document.documentElement).getPropertyValue('--findingRed');
    const colorFindingOrange = getComputedStyle(document.documentElement).getPropertyValue('--findingOrange');
    const colorFindingYellow = getComputedStyle(document.documentElement).getPropertyValue('--findingYellow');
    const colorFindingGreen = getComputedStyle(document.documentElement).getPropertyValue('--findingGreen');
    const colorTextNormal = getComputedStyle(document.documentElement).getPropertyValue('--bs-body-color');
    const colorTextWhite = '#ffffff';

    // Values of the support data graph
    const vulns_total = {{INSIDER__VULNS_ALL}}
    const vulns_low = {{INSIDER__VULNS_LOW}}
    const vulns_medium = {{INSIDER__VULNS_MEDIUM}}
    const vulns_high = {{INSIDER__VULNS_HIGH}}
    const vulns_critical = {{INSIDER__VULNS_CRITICAL}}

    // Dimensions and margins of the support data graph
    const stats_viz = 680,
    vuln_data_viz_height = 450,
    vuln_data_viz_margin = 50;

    // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
    const radius = Math.min(stats_viz, vuln_data_viz_height) / 2 - vuln_data_viz_margin
    const svg = d3.select("#stats_viz")
      .append("svg")
        .attr("width", stats_viz)
        .attr("height", vuln_data_viz_height)
      .append("g")
        .attr("transform", `translate(${stats_viz/2},${vuln_data_viz_height/2})`);

    const support_data = [
      { id: 1, label: 'Low', count: vulns_low, color: colorFindingYellow },
      { id: 2, label: 'Medium', count: vulns_medium, color: colorFindingOrange },
      { id: 3, label: 'High', count: vulns_high, color: colorFindingRed },
      { id: 4, label: 'Critical', count: vulns_critical, color: colorFindingPurple },
    ];

    // Define the log scale
    /*const logScale = d3.scaleLog()
    .domain([1, d3.max(support_data, d => d.count)+1]) // Set the domain to start from 1 to avoid log(0)
    .range([1, 20]); // Map the log scale to values between 1 and 20*/

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
        .attr('x', -stats_viz / 4) // Adjust position as needed
        .attr('y', -vuln_data_viz_height / 12) // Adjust position as needed
        .attr('width', stats_viz / 2) // Adjust size as needed
        .attr('height', vuln_data_viz_height / 2 ); // Adjust size as needed

    foreignObject.append('xhtml:div')
       .html('<div style="text-align:center;color:black;font-size:16px;"><span style="font-size:30px;font-weight:bold;">'+vulns_total+'</span><br/>Vulnerabilities</div>');

  </script>
</body>
</html>
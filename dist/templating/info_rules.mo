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
  <title>Generated Application Reports</title>
  <!-- Bootstrap core CSS -->
  <link href="./static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="./static/img/favicon.ico" rel="shortcut icon" type="image/x-icon"/>
  <link href="./static/css/core.css" rel="stylesheet">
  <style>
    h4.panel-title.panel-heading { margin-bottom: 0em!important; }
    .container.mb-3 { margin-bottom: 0rem!important;}
    /* Center badge counting tools */
    span.badge.bg-dark, span.badge.bg-secondary, a.badge.bg-secondary, a.badge.bg-light.text-dark { vertical-align:middle; margin-top: -0.3em; }
    a.badge.bg-light.text-dark {text-decoration: none;}
    /* Foldable list of tools used */ 
    .panel-heading { padding: 0; border:0; }
    .panel-title>span, .panel-title>a:active{
      display:block;
      padding-top:15px;
      padding-bottom:15px;
      color:#212529;
      text-transform:uppercase;
      word-spacing:3px;
      text-decoration:none;
    }
  </style>
</head>

<body>
  <!-- Header -->
  <header class="navbar navbar-expand navbar-dark flex-column flex-md-row bd-navbar">
    <div class="container">
      <a class="navbar-brand mr-0 me-md-2" href="./index.html"><img class="mr-3 me-3 filter-white company-logo" src="./static/img/company.svg" alt="VMware"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link" href="./index.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./cloud{{GROUP_POSTFIX}}.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        {{#HAS_SECURITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./security{{GROUP_POSTFIX}}.html">Security</a></li>{{/HAS_SECURITY_REPORT}}
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./quality{{GROUP_POSTFIX}}.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
        {{#HAS_LANGUAGES_REPORT}}<li class="nav-item"><a class="nav-link" href="./languages.html">Languages</a></li>{{/HAS_LANGUAGES_REPORT}}
        <li class="nav-item">
          <a class="nav-link active" href="./info.html"><i class="bi bi-speedometer"></i></a>
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
      <h1 class="display-4 mt-4 mb-2">Analysis information</h1>
      <div>
        <p class="lead mb-3 text-black-50">Collected data on the tool executions.</p>
      </div>
    </div>
  </div>

  <div class="container">
    <br/>
    <ul class="nav nav-tabs">
      <li class="nav-item">
        <a class="nav-link tab-nav-link" href="./info.html">Timelines</a>
      </li>
      <li class="nav-item">
        <a class="nav-link active" aria-current="page" href="#">Rules</a>
      </li>
    </ul>
    <br/>
    <div class="row">
      <h4 class="panel-title">Rules available for each tool</h4>
      <p style="margin-bottom: 0px;">Logarithmic treemap visualizing the number of rules per tool sorted by category: <span style="color:#DC3545">security</span>, <span style="color:#1F8637">quality</span>,  <span style="color:#0081D1">cloud-readiness</span>. <span class="badge bg-secondary">{{TOOLS_COUNT}}</span> out of <span class="badge bg-secondary">18</span> tools used.</p>
      <div id="rules_summary"></div>
    </div>
  </div>

  <!-- Footer -->
  <section class="footer-component footer-container">
    <footer class="footer">
      <div class="row">
        <div class="col-lg-12 col-md-12 footer-links-wrapper">
          <div class="footer-links mt-3">
            <span class="mb-3">
              <a href="https://www.vmware.com/" rel="noreferrer" target="_blank"><img class="mr-3 me-2 company-logo" src="./static/img/company.svg" alt="VMware"/></a>
              Generated with
              <a href="{{NAV_LINK}}" class="text-xxss text-black mb-3 ml-lg-3" rel="noreferrer" target="_blank">Application Portfolio Auditor</a>
              v.{{TOOL_VERSION}} from
              <a href="https://tanzu.vmware.com/labs" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Tanzu Labs" title="Tanzu Labs" rel="noreferrer" target="_blank">Tanzu Labs</a>
              on {{REPORT_TIMESTAMP}}</span>
          </div>
          <div class="footer-links mt-3">
              <span class="mb-3">&#169; 2024 Broadcom</span>
              <a href="https://www.vmware.com/help/legal.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Terms of Use" title="Terms of Use" name="nav_footer_bottom : Terms of Use" rel="noreferrer" target="_blank">Terms of Use</a> 
              <a href="https://www.vmware.com/help/privacy/california-privacy-rights.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Your California Privacy Rights" title="Your California Privacy Rights" name="nav_footer_bottom : Your California Privacy Rights" rel="noreferrer" target="_blank">Your California Privacy Rights</a> 
              <a href="https://www.vmware.com/help/privacy.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Privacy" title="Privacy" name="nav_footer_bottom : Privacy" rel="noreferrer" target="_blank">Privacy</a> 
              <a href="https://www.vmware.com/help/accessibility.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Accessibility" title="Accessibility" name="nav_footer_bottom : Accessibility" rel="noreferrer" target="_blank">Accessibility</a> 
              <a href="https://www.vmware.com/help/trademarks.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Trademarks" title="Trademarks" name="nav_footer_bottom : Trademarks" rel="noreferrer" target="_blank">Trademarks</a> 
              <a href="https://www.vmware.com/topics/glossary.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Glossary" title="Glossary" name="nav_footer_bottom : Glossary" rel="noreferrer" target="_blank">Glossary</a> 
              <a href="https://www.vmware.com/help.html" class="text-xxss text-black mb-3 ml-lg-3" aria-label="Help" title="Help" name="nav_footer_bottom : Help" rel="noreferrer" target="_blank">Help</a> 
          </div>
          <div class="footer-disclaimer mt-3">
            <span class="mb-3">This website does not use cookies or other tracking technology.</span>
          </div>
        </div>
      </div>
    </footer>
  </section>

  <!-- Bootstrap core JavaScript -->
  <script src="./static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/js/bootstrap.bundle.min.js"></script>
  <!-- D3.js-->
  <script src="./static/js/d3.v{{D3_VERSION}}.min.js"></script>

  <script>
    // set the dimensions and margins of the graph
    const margin = {top: 0, right: 0, bottom: 10, left: 0},
      width = 1200 - margin.left - margin.right,
      height = 800 - margin.top - margin.bottom;
    
    // append the svg object to the body of the page
    const svg = d3.select("#rules_summary")
    .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .append("g")
      .attr("transform",
            `translate(${margin.left}, ${margin.top})`);
    
    // "https://raw.githubusercontent.com/holtzy/D3-graph-gallery/master/DATA/data_dendrogram_full.json"
    const data = {
      "children":[
        {
          "name":"Security",
          "children":[
            {
              "name":"OWASP Dependency Check",
              "active":{{#HAS_ODC_REPORT}}true{{/HAS_ODC_REPORT}}{{^HAS_ODC_REPORT}}false{{/HAS_ODC_REPORT}},
              "value":{{ ODC_RULES }},
              "url":"https://owasp.org/www-project-dependency-check/"
            },
            {
              "name":"ShiftLeft Scan",
              "active":{{#HAS_SLSCAN_REPORT}}true{{/HAS_SLSCAN_REPORT}}{{^HAS_SLSCAN_REPORT}}false{{/HAS_SLSCAN_REPORT}},
              "value":{{ SLSCAN_RULES }},
              "url":"https://github.com/ShiftLeftSecurity/sast-scan"
            },
            {
              "name":"Find Security",
              "name_ext":"Bugs",
              "active":{{#HAS_FSB_REPORT}}true{{/HAS_FSB_REPORT}}{{^HAS_FSB_REPORT}}false{{/HAS_FSB_REPORT}},
              "value":{{ FSB_RULES }},
              "url":"https://find-sec-bugs.github.io/"
            },
            {
              "name":"Insider",
              "active":{{#HAS_INSIDER_REPORT}}true{{/HAS_INSIDER_REPORT}}{{^HAS_INSIDER_REPORT}}false{{/HAS_INSIDER_REPORT}},
              "value":{{ INSIDER_RULES }},
              "url":"https://github.com/insidersec/insider"
            },
            {
              "name":"Grype",
              "active":{{#HAS_GRYPE_REPORT}}true{{/HAS_GRYPE_REPORT}}{{^HAS_GRYPE_REPORT}}false{{/HAS_GRYPE_REPORT}},
              "value":{{ GRYPE_RULES }},
              "url":"https://github.com/anchore/grype"
            },
            {
              "name":"Trivy",
              "active":{{#HAS_TRIVY_REPORT}}true{{/HAS_TRIVY_REPORT}}{{^HAS_TRIVY_REPORT}}false{{/HAS_TRIVY_REPORT}},
              "value":{{ TRIVY_RULES }},
              "url":"https://github.com/aquasecurity/trivy"
            },
            {
              "name":"OSV",
              "active":{{#HAS_OSV_REPORT}}true{{/HAS_OSV_REPORT}}{{^HAS_OSV_REPORT}}false{{/HAS_OSV_REPORT}},
              "value":{{ OSV_RULES }},
              "url":"https://osv.dev/"
            },
            {
              "name":"Bearer",
              "active":{{#HAS_BEARER_REPORT}}true{{/HAS_BEARER_REPORT}}{{^HAS_BEARER_REPORT}}false{{/HAS_BEARER_REPORT}},
              "value":{{ BEARER_RULES }},
              "url":"https://github.com/Bearer/bearer"
            }
          ]
        },
        {
          "name":"Quality",
          "children":[
            {
              "name":"CLOC",
              "active":{{#HAS_LANGUAGES_REPORT}}true{{/HAS_LANGUAGES_REPORT}}{{^HAS_LANGUAGES_REPORT}}false{{/HAS_LANGUAGES_REPORT}},
              "value":{{ CLOC_RULES }},
              "url":"https://github.com/AlDanial/cloc"
            },
            {
              "name":"GitHub",
              "name_ext":"Linguist",
              "active":{{#HAS_LANGUAGES_REPORT}}true{{/HAS_LANGUAGES_REPORT}}{{^HAS_LANGUAGES_REPORT}}false{{/HAS_LANGUAGES_REPORT}},
              "value":{{ LINGUIST_RULES }},
              "url":"https://github.com/github/linguist"
            },
            {
              "name":"Microsoft",
              "name_ext":"App Inspector",
              "active":{{#HAS_MAI_REPORT}}true{{/HAS_MAI_REPORT}}{{^HAS_MAI_REPORT}}false{{/HAS_MAI_REPORT}},
              "value":{{ MAI_RULES }},
              "url":"https://github.com/Microsoft/ApplicationInspector"
            },
            {
              "name":"Scancode",
              "name_ext":"Toolkit",
              "active":{{#HAS_SCANCODE_REPORT}}true{{/HAS_SCANCODE_REPORT}}{{^HAS_SCANCODE_REPORT}}false{{/HAS_SCANCODE_REPORT}},
              "value":{{ SCANCODE_RULES }},
              "url":"https://github.com/nexB/scancode-toolkit"
            },
            {
              "name":"PMD",
              "name_ext":"Analyzer",
              "active":{{#HAS_PMD_REPORT}}true{{/HAS_PMD_REPORT}}{{^HAS_PMD_REPORT}}false{{/HAS_PMD_REPORT}},
              "value":{{ PMD_RULES }},
              "url":"https://pmd.github.io/"
            },
            {
              "name":"Archeo",
              "active":{{#HAS_ARCHEO_REPORT}}true{{/HAS_ARCHEO_REPORT}}{{^HAS_ARCHEO_REPORT}}false{{/HAS_ARCHEO_REPORT}},
              "value":{{ ARCHEO_RULES }},
              "url":"https://github.com/vmware-tanzu/application-portfolio-auditor"
            }
          ]
        },
        {
          "name":"Cloud-Readiness",
          "children":[
            {
              "name":"Windup",
              "active":{{#HAS_WINDUP_REPORT}}true{{/HAS_WINDUP_REPORT}}{{^HAS_WINDUP_REPORT}}false{{/HAS_WINDUP_REPORT}},
              "value":{{ WINDUP_RULES }},
              "url":"https://github.com/windup/windup"
            },
            {
              "name":"IBM WAMT",
              "active":{{#HAS_WAMT_REPORT}}true{{/HAS_WAMT_REPORT}}{{^HAS_WAMT_REPORT}}false{{/HAS_WAMT_REPORT}},
              "value":{{ WAMT_RULES }},
              "url":"https://www.ibm.com/support/pages/websphere-application-server-migration-toolkit"
            },
            {
              "name":"Cloud Suitability Analyzer",
              "active":{{#HAS_CSA_REPORT}}true{{/HAS_CSA_REPORT}}{{^HAS_CSA_REPORT}}false{{/HAS_CSA_REPORT}},
              "value":{{ CSA_RULES }},
              "url":"https://github.com/vmware-tanzu/cloud-suitability-analyzer"
            }
          ]
        }
      ]
    };

    // Sort by descending value
    data.children.forEach(function(category) {
      category.children.sort(function(a, b) {
        return b.value - a.value;
      });
    });

    // Inspired from https://stackoverflow.com/questions/25245044/treemap-aggregate-values-which-are-too-small-to-be-visualized-correctly
    var powerScale = d3.scalePow().exponent(0.3).domain([1,1000]).range([0, 100000]);

    var format = d3.format(",d");

    // Give the data to this cluster layout:
    const root = d3.hierarchy(data).sum(function(d){ return powerScale(d.value)} ) // Here the size of each leave is given in the 'value' field in input data

    // Then d3.treemap computes the position of each element of the hierarchy
    d3.treemap()
    .size([width, height])
    .paddingTop(28)
    .paddingRight(7)
    .paddingInner(3)
    (root)

    // prepare a color scale
    const color = d3.scaleOrdinal()
    .domain(["Security", "Quality", "Cloud-Readiness"])
    .range([ "#DC3545", "#1F8637", "#0081D1"])

    // And a opacity scale
    const opacity = d3.scaleLinear()
    .domain([100, 1000])
    .range([.5,1])

    // use this information to add rectangles:
    svg
    .selectAll("rect")
    .data(root.leaves())
    .join("rect")
        .attr('x', function (d) { return d.x0; })
        .attr('y', function (d) { return d.y0; })
        .attr('width', function (d) { return d.x1 - d.x0; })
        .attr('height', function (d) { return d.y1 - d.y0; })
        .style("stroke", "black")
        .style("fill", function(d){ if(d.data.active){ return color(d.parent.data.name)} else {return '#9DA3A8'}} )
        .style("opacity", function(d){ return opacity(d.data.value)})
        .attr("onclick", function(d){ return "window.open('"+d.data.url+"');"} )

    // and to add the text labels
    svg
    .selectAll("text")
    .data(root.leaves())
    .enter()
      .append("text")
        .append("tspan")
          .attr("x", function(d){ return d.x0+5})    // to adjust position (more right)
          .attr("y", function(d){ return d.y0+20})    // to adjust position (lower)
          .text(function(d){ return d.data.name })
          .attr("font-size", "16px")
          .attr("fill", "white")
        .filter(function(d){ return Boolean(d.data.name_ext)})
        .append("tspan")
          .attr("x", function(d){ return d.x0+5})    // to adjust position (more right)
          .attr("y", function(d){ return d.y0+36})    // to adjust position (lower)
          .text(function(d){ return d.data.name_ext })
          .attr("font-size", "16px")
          .attr("fill", "white")

    // and add the value
    svg
    .selectAll("vals")
    .data(root.leaves())
    .enter()
    .append("text")
        .attr("x", function(d){ return d.x0+5})    // to adjust position (more right)
        .attr("y", function(d){ if(Boolean(d.data.name_ext)){return d.y0+35+16} else {return d.y0+35}}) // to adjust position (lower)
        .text(function(d){ return format(d.data.value) })
        .attr("font-size", "11px")
        .attr("fill", "white")

    // Add titles for 3 groups
    svg
    .selectAll("titles")
    .data(root.descendants().filter(function(d){return d.depth==1}))
    .enter()
    .append("text")
        .attr("x", function(d){ return d.x0})
        .attr("y", function(d){ return d.y0+21})
        .text(function(d){ return d.data.name })
        .attr("font-size", "19px")
        .attr("fill",  function(d){ return color(d.data.name)} )
    </script>  
</body>
</html>

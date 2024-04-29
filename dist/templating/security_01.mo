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
  <link href="./static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="./static/img/favicon.ico" rel="shortcut icon" type="image/x-icon"/>
  <link href="./static/css/core.css" rel="stylesheet">
  <style>
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 0px auto;
    } 
    /* Zebra striping */
    tr:nth-of-type(odd) {
      background: #f2f2f2;
    }
    th {
      background: #333;
      color: white;
      font-weight: bold;
      cursor: s-resize;
      background-repeat: no-repeat;
      background-position: 3% center;
    }
    td, th {
      padding: 6px;
      border: 1px solid #ccc;
      text-align: left;
    }
    th.des:after {
      content: "\21E3";
    }
    th.aes:after {
      content: "\21E1";
    }
    th { text-align:center }
    tr:nth-child(1), td:nth-child(1) { width: 35%; }
    tr:nth-child(2), td:nth-child(2) { width: 5%; }
    /* Center badge counting tools */
    span.badge.bg-dark, span.badge.bg-secondary, a.badge.bg-secondary, a.badge.bg-light.text-dark { vertical-align:middle; margin-top: -0.3em; }
    a.badge.bg-light.text-dark {text-decoration: none;}

    /* Foldable list of tools used */ 
    .panel-heading { padding: 0; border:0; }
    .panel-title>a, .panel-title>a:active{
      display:block;
      padding-top:15px;
      padding-bottom:15px;
      color:#212529;
      text-transform:uppercase;
      word-spacing:3px;
      text-decoration:none;
    }
    .panel-heading a:before {
      content: "\f282";
      font-family: 'bootstrap-icons' !important;
      speak: none;
      float: right;
      transition: all 0.5s;
    }
    .panel-heading.active a:before {
      -webkit-transform: rotate(180deg);
      -moz-transform: rotate(180deg);
      transform: rotate(180deg);
    }
    .bd-masthead { position: relative; padding: 3rem 15px; }
    div.card.card-body ul { margin-bottom: 0rem!important; }
    div.card.card-body { padding: 1rem; background: #f2f2f2 !important; margin-bottom: 1rem!important; }
    div#tools.bd-masthead.py-3.mb-3 {
      padding-bottom: 0rem!important;
      padding-top: 0.3rem!important;
    }
    .container.mb-3 { margin-bottom: 0rem!important;}
    .nolink, .nolink:link, .nolink:visited, .nolink:hover, .nolink:active {
      text-decoration:none!important;
      color:#212529!important;
    }
  </style>
</head>

<body>
  <!-- Header -->
  <header class="navbar navbar-expand navbar-dark flex-column flex-md-row bd-navbar">
    <div class="container">
      <a class="navbar-brand mr-0 me-md-2" href="./index.html"><img class="mr-3 me-3 filter-white company-icon" src="./static/img/company-icon.svg" alt="VMware"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link" href="./index.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./cloud.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        <li class="nav-item"><a class="nav-link active" href="#">Security</a></li>
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./quality.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
        {{#HAS_LANGUAGES_REPORT}}<li class="nav-item"><a class="nav-link" href="./languages.html">Languages</a></li>{{/HAS_LANGUAGES_REPORT}}
        <li class="nav-item">
          <a class="nav-link" href="./info.html"><i class="bi bi-speedometer"></i></a>
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
      <div class="panel-heading">
        <h4 class="panel-title">
          <a data-bs-toggle="collapse" href="#collapseTools" role="button" aria-expanded="false" aria-controls="collapseTools">
            <span class="badge bg-dark">{{TOOLS_SECURITY_COUNT}}</span> analysis tool{{#HAS_MULTIPLE_SECURITY_TOOLS}}s{{/HAS_MULTIPLE_SECURITY_TOOLS}} used
          </a>
        </h4>
        </div>
        <div class="collapse" id="collapseTools">
          <div class="panel-body">
            <div class="container">
{{#HAS_ODC_REPORT}}
            <div class="d-flex">
              <a href="{{ODC_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/owasp.svg" height="50" width="50" alt="Open Web Application Security Project Dependency-Check"></a>
              <div>
                <h5 class="mt-0 mb-1">Open Web Application Security Project (OWASP) Dependency-Check <a href="https://www.owasp.org/index.php/OWASP_Dependency_Check" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{OWASP_DC_VERSION}}</a></h5>
                Identifies well-known security vulnerabilities in embedded libraries. (<a href="{{ODC_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{ODC_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_ODC_REPORT}}
{{#HAS_FSB_REPORT}}
            <div class="d-flex">
              <a href="{{FSB_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/fsb.png" height="50" width="50" alt="Find Security Bugs"></a>
              <div>
                <h5 class="mt-0 mb-1">Find Security Bugs (FSB) <a href="https://find-sec-bugs.github.io/" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{FSB_VERSION}}</a></h5>
                Audits security of Java applications. (<a href="{{FSB_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{FSB_CSV}}" rel="noreferrer" target="_blank" class="report-link">csv</a> - <a href="{{FSB_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_FSB_REPORT}}
{{#HAS_SLSCAN_REPORT}}
            <div class="d-flex">
              <a href="{{SLSCAN_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/scan-light.png" height="50" width="50" alt="ShiftLeft SAST Scan"></a>
              <div>
                <h5 class="mt-0 mb-1">ShiftLeft SAST Scan <a href="https://github.com/ShiftLeftSecurity/sast-scan" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SLSCAN_VERSION}}</a></h5>
                Identifies security vulnerabilities focussing on the <a href="https://owasp.org/www-project-top-ten/" rel="noreferrer" target="_blank" class="link">OWASP Top 10</a>. (<a href="{{SLSCAN_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{SLSCAN_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_SLSCAN_REPORT}}
{{#HAS_INSIDER_REPORT}}
            <div class="d-flex">
              <a href="{{INSIDER_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/insider.png" height="50" width="50" alt="Insider SAST"></a>
              <div>
                <h5 class="mt-0 mb-1">Insider SAST <a href="https://github.com/insidersec/insider" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{INSIDER_VERSION}}</a></h5>
                Identifies locally various kinds of security issues in application code. (<a href="{{INSIDER_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{INSIDER_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_INSIDER_REPORT}}
{{#HAS_GRYPE_REPORT}}
            <div class="d-flex">
              <a href="{{GRYPE_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/grype.png" height="50" width="50" alt="Grype"></a>
              <div>
                <h5 class="mt-0 mb-1">Grype <a href="https://github.com/anchore/grype" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{GRYPE_VERSION}}</a> and Syft <a href="https://github.com/anchore/syft" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SYFT_VERSION}}</a></h5>
                Identifies known security vulnerabilities in application binaries and code. (<a href="{{GRYPE_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{GRYPE_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_GRYPE_REPORT}}
{{#HAS_TRIVY_REPORT}}
            <div class="d-flex">
              <a href="{{TRIVY_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/trivy.svg" height="50" width="50" alt="Trivy"></a>
              <div>
                <h5 class="mt-0 mb-1">Trivy <a href="https://github.com/aquasecurity/trivy" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{TRIVY_VERSION}}</a></h5>
                Find vulnerabilities, misconfigurations, secrets. (<a href="{{TRIVY_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{TRIVY_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_TRIVY_REPORT}}
{{#HAS_OSV_REPORT}}
            <div class="d-flex">
              <a href="{{OSV_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/osv.png" height="50" width="50" alt="OSV"></a>
              <div>
                <h5 class="mt-0 mb-1">OSV <a href="https://github.com/google/osv.dev" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{OSV_VERSION}}</a> and Syft <a href="https://github.com/anchore/syft" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SYFT_VERSION}}</a></h5>
                Find vulnerable dependencies according to the OSV database. (<a href="{{OSV_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{OSV_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_OSV_REPORT}}
{{#HAS_BEARER_REPORT}}
            <div class="d-flex">
              <a href="{{BEARER_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/bearer.png" height="50" width="50" alt="Bearer"></a>
              <div>
                <h5 class="mt-0 mb-1">Bearer <a href="https://github.com/Bearer/bearer" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{BEARER_VERSION}}</a></h5>
                Discover, filter and prioritize security and privacy risks in your code. (<a href="{{BEARER_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{BEARER_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_BEARER_REPORT}}
          </div>
        </div> 
      </div> 
    </div>
  </div>

{{#HAS_SECURITY_REPORT_TABLE}}
  <!-- Page Content -->
  <div class="container mb-3">
    <div class="col">
      <div class="row">
        <p><a class="nolink" data-bs-toggle="collapse" href="#multiCollapseInfo" role="button" aria-expanded="false" aria-controls="multiCollapseInfo"><i class="bi bi-info-circle-fill"></i> Click on a cell of the heatmap to open the linked report. The <span class="text-bold">darker</span> a cell is, the higher is its score, and the <span class="text-bold">more</span> vulnerable is its application.</a></p>
      </div>
    </div>
    <div class="col" id="info">
      <div class="row">
        <div class="collapse multi-collapse" id="multiCollapseInfo">
          <div class="card card-body">
            <p>As columns, you will find respectively the ...</p>
            <ul>
            {{#HAS_ODC_REPORT}}<li>count of vulnerabilities with 'Low', 'Medium', 'High', and 'Critical' severity found by OWASP Dependency-Check in embedded libraries.</li>
            <li>total number of vulnerable libraries found by OWASP Dependency-Check.</li>{{/HAS_ODC_REPORT}}
            {{#HAS_FSB_REPORT}}<li>count of 'Low', 'Medium', 'High' severity security warnings found by Find Security Bugs (FSB).</li>
            <li>total number of security warnings issued by Find Security Bugs (FSB).</li>{{/HAS_FSB_REPORT}}
            {{#HAS_SLSCAN_REPORT}}<li>total number of vulnerabilities found by ShiftLeft SAST Scan (SLScan).</li>{{/HAS_SLSCAN_REPORT}}
            {{#HAS_INSIDER_REPORT}}<li>total number of vulnerabilities found by Insider SAST.</li>{{/HAS_INSIDER_REPORT}}
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Inspired from https://github.com/shanegibney/d3-v4-sortable-table/blob/master/index.html -->
  <div class="container">
    <div class="flex-column">
      <div id="page-wrap">
      </div>
    </div>
  </div>
  <!-- /.container -->
{{/HAS_SECURITY_REPORT_TABLE}}

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
  <script src="./static/js/jquery-{{JQUERY_VERSION}}.min.js"></script>
  <script src="./static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/js/bootstrap.bundle.min.js"></script>
  <script src="./static/js/d3.v{{D3_VERSION}}.min.js"></script>
{{#HAS_SECURITY_REPORT_TABLE}}
<script>
{{/HAS_SECURITY_REPORT_TABLE}}
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
  <title>Quality Report</title>
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
      <a class="navbar-brand mr-0 me-md-2" href="./index.html"><img class="mr-3 me-3 filter-white company-logo" src="./static/img/company.svg" alt="VMware"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link" href="./index{{GROUP_POSTFIX}}.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./cloud{{GROUP_POSTFIX}}.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        {{#HAS_SECURITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./security{{GROUP_POSTFIX}}.html">Security</a></li>{{/HAS_SECURITY_REPORT}}
        <li class="nav-item"><a class="nav-link active" href="#">Quality</a></li>
        {{#HAS_LANGUAGES_REPORT}}<li class="nav-item"><a class="nav-link" href="./languages.html">Languages</a></li>{{/HAS_LANGUAGES_REPORT}}
        <li class="nav-item dropdown">
          <a class="nav-item nav-link dropdown-toggle me-md-2" href="#" id="bd-versions" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">&nbsp;</a>
          <div class="dropdown-menu dropdown-menu-md-right" aria-labelledby="bd-versions">
            {{DROPDOWN_ITEMS}}
          </div>
        </li>
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
      <h1 class="display-4 mt-4 mb-2">Quality reports</h1>
      <div>
        <p class="lead mb-3 text-black-50">Consolidated code quality findings.</p>
      </div>
    </div>
  </div>

  <!-- Tools -->
  <div class="bd-masthead py-3 mb-3" id="tools" role="main">
    <div class="container">
      <div class="panel-heading">
        <h4 class="panel-title">
          <a data-bs-toggle="collapse" href="#collapseTools" role="button" aria-expanded="false" aria-controls="collapseTools">
            <span class="badge bg-dark">{{TOOLS_QUALITY_COUNT}}</span> analysis tool{{#HAS_MULTIPLE_QUALITY_TOOLS}}s{{/HAS_MULTIPLE_QUALITY_TOOLS}} used
          </a>
        </h4>
      </div>
      <div class="collapse" id="collapseTools">
        <div class="panel-body">
          <div class="container">
{{#HAS_ARCHEO_REPORT}}
            <div class="d-flex">
              <a href="{{ARCHEO_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/archeo.png" height="50" width="50" alt="Archeo"></a>
              <div>
                <h5 class="mt-0 mb-1">Archeologist <a href="https://github.com/vmware-tanzu/application-portfolio-auditor" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{TOOL_VERSION}}</a></h5>
                Find unsupported and unnecessary ancient libraries in your applications. (<a href="{{ARCHEO_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{ARCHEO_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_ARCHEO_REPORT}}
{{#HAS_PMD_REPORT}}
            <div class="d-flex">
              <a href="{{PMD_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/pmd.png" width="50" alt="PMD Source Code Analyzer"></a>
              <div>
                <h5 class="mt-0 mb-1">PMD Source Code Analyzer <a href="https://pmd.github.io/" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{PMD_VERSION}}</a></h5>
                Extensible cross-language static code analyzer. (<a href="{{PMD_URL}}/pmd" rel="noreferrer" target="_blank" class="report-link">flaw</a> & <a href="{{PMD_URL}}/cpd" rel="noreferrer" target="_blank" class="report-link">copy-paste</a> reports - <a href="{{PMD_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_PMD_REPORT}}
{{#HAS_SCANCODE_REPORT}}
            <div class="d-flex">
              <a href="{{SCANCODE_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/scancode.png" height="50" width="50" alt="ScanCode Toolkit"></a>
              <div>
                <h5 class="mt-0 mb-1">ScanCode Toolkit <a href="https://github.com/nexB/scancode-toolkit" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SCANCODE_VERSION}}</a></h5>
                Detect licenses, copyrights, and package manifests of embedded libraries. (<a href="{{SCANCODE_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{SCANCODE_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_SCANCODE_REPORT}}
{{#HAS_MAI_REPORT}}
            <div class="d-flex">
              <a href="{{MAI_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/microsoft.png" height="50" width="50" alt="Microsoft Application Inspector"></a>
              <div>
                <h5 class="mt-0 mb-1">Microsoft Application Inspector <a href="https://github.com/Microsoft/ApplicationInspector" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{MAI_VERSION}}</a></h5>
                Identify what is in the applications using static analysis. (<a href="{{MAI_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{MAI_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
                <br/><br/>
              </div>
            </div>
{{/HAS_MAI_REPORT}}
          </div>
        </div> 
      </div> 
    </div>
  </div>

  <!-- Page Content -->
  <div class="container mb-3">
    <div class="col">
      <div class="row">
        <p><a class="nolink" data-bs-toggle="collapse" href="#multiCollapseInfo" role="button" aria-expanded="false" aria-controls="multiCollapseInfo"><i class="bi bi-info-circle-fill"></i> Click on a cell of the heatmap to open the linked report. The <span class="text-bold">darker</span> a cell is, the higher is its score, and the <span class="text-bold">worse</span> is its quality.</a></p>
      </div>
    </div>
    <div class="col" id="info">
      <div class="row">
        <div class="collapse multi-collapse" id="multiCollapseInfo">
          <div class="card card-body">
            <p>As columns, you will find respectively the ...</p>
            <ul>
              {{#HAS_PMD_REPORT}}<li>numbers of triggered PMD rules and violations.</li>{{/HAS_PMD_REPORT}}
              {{#HAS_PMD_REPORT}}<li>numbers of copy-pasted source code fragments (several lines), lines (several tokens), and tokens (chars and operators).</li>{{/HAS_PMD_REPORT}}
              {{#HAS_SCANCODE_REPORT}}<li>numbers of embedded licenses and copyrights detected by ScanCode.</li>{{/HAS_SCANCODE_REPORT}}
              {{#HAS_MAI_REPORT}}<li>numbers of detected features types ('tags') by MAI.</li>{{/HAS_MAI_REPORT}}
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>

  <div class="container">
    <div class="flex-column">
      <div id="page-wrap">
      </div>
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
  <script src="./static/js/jquery-{{JQUERY_VERSION}}.min.js"></script>
  <script src="./static/bootstrap-{{BOOTSTRAP_VERSION}}-dist/js/bootstrap.bundle.min.js"></script>
  <script src="./static/js/d3.v{{D3_VERSION}}.min.js"></script>
<script>
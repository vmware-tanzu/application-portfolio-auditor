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
    tr:nth-child(1), td:nth-child(1) { width: 15%; }
    tr:nth-child(2), td:nth-child(2) { width: 12%; }
    tr:nth-child(3), td:nth-child(3) { width: 5%; }
    tr:nth-child(4), td:nth-child(4) { width: 5%; }
    tr:nth-child(5), td:nth-child(5) { width: 5%; }
    tr:nth-child(6), td:nth-child(6) { width: 43%; word-break:break-word;}
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
        <li class="nav-item"><a class="nav-link" href="./../index{{GROUP_POSTFIX}}.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./../cloud{{GROUP_POSTFIX}}.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        <li class="nav-item"><a class="nav-link active" href="./../security.html">Security</a></li>
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./../quality{{GROUP_POSTFIX}}.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
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
          <a href="./../14__TRIVY/" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./../static/img/trivy.svg" height="50" width="50" alt="{{TRIVY_VERSION}}"></a>
          <div>
            <h5 class="mt-0 mb-1">Trivy <a href="https://github.com/aquasecurity/trivy" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{TRIVY_VERSION}}</a></h5>
            Find vulnerabilities, misconfigurations, secrets. (<a href="{{TRIVY_REPORT_DIR}}/" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{TRIVY_REPORT_DIR}}/../14__TRIVY.log" rel="noreferrer" target="_blank" class="report-link">log</a>)
          </div>
      </div>
    </div>
  </div>

  <div class="container">
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="./../security.html">Security</a></li>
        <li class="breadcrumb-item active">Trivy</li>
        <li class="breadcrumb-item">{{APP}}</li>
      </ol>
    </nav>
  </div>

  <div class="container">

    <div class="row justify-content-center">
      <div class="col-8">
        <div id="vuln_viz"></div>
      </div>
      <div class="col-4">
        <div class="card mt-5 border-0">
          <div class="row gy-2">
            <div class="col-12">
              <div class="card border-0" style="background-color: #333333; color: #ffffff;">
                <div class="card-body">
                  <div class="row align-items-center">
                    <div class="col-6">
                      <div class="d-flex align-items-center">
                        <div>
                          <h6 class="m-0">Vulnerable libraries</h6>
                        </div>
                      </div>
                    </div>
                    <div class="col-6">
                      <h6 class="text-end"><span class="h3 m-0">{{TRIVY__VULN_LIBS}}&nbsp;</span><span class="m-0 h6">out of</span><span class="h3 m-0">&nbsp;{{TRIVY__ALL_LIBS}}</span></h6>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="col-12">
              <div class="card border-0" style="background-color: #333333; color: #ffffff;">
                <div class="card-body">
                  <div class="row align-items-center">
                    <div class="col-6">
                      <div class="d-flex align-items-center">
                        <div>
                          <h6 class="m-0">Total vulnerabilities</h6>
                        </div>
                      </div>
                    </div>
                    <div class="col-6">
                      <h6 class="h3 text-end m-0">{{TRIVY__VULNS_ALL}}</h6>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <p>The following table summarizes the findings of <span class="text-bold">Trivy</span> while analyzing <span class="text-bold">{{APP}}</span>.</p>
    </div>
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
    var app_name="{{APP}}"
    const longText = `\

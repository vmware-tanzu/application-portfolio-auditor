<!--
    Copyright 2019-2023 VMware, Inc.
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
  <link href="./../static/css/core.css" rel="stylesheet">
  <style>
    span.badge.bg-dark, span.badge.bg-secondary, a.badge.bg-secondary, a.badge.bg-light.text-dark { vertical-align:middle; margin-top: -0.3em; }
    a.badge.bg-light.text-dark {text-decoration: none;}
  </style>
</head>

<body>
  <!-- Header -->
  <header class="navbar navbar-expand navbar-dark flex-column flex-md-row bd-navbar">
    <div class="container">
      <a class="navbar-brand mr-0 me-md-2" href="./../index.html"><img class="mr-3 me-3 filter-white" src="./../static/img/vmware.svg" height="18" alt="Tanzu"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link" href="./../index{{GROUP_POSTFIX}}.html">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./../cloud{{GROUP_POSTFIX}}.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        <li class="nav-item"><a class="nav-link active" href="./../security.html">Security</a></li>
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./../quality{{GROUP_POSTFIX}}.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
        {{#HAS_LANGUAGES_REPORT}}<li class="nav-item"><a class="nav-link" href="./../languages.html">Languages</a></li>{{/HAS_LANGUAGES_REPORT}}
        <li class="nav-item dropdown">
          <a class="nav-item nav-link dropdown-toggle me-md-2" href="#" id="bd-versions" data-bs-toggle="dropdown" aria-haspopup="true" aria-expanded="false">&nbsp;</a>
          <div class="dropdown-menu dropdown-menu-md-right" aria-labelledby="bd-versions">
            <a class="dropdown-item active" href="#">{{APP_GROUP}}</a>
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
          <a href="./../13__GRYPE__{{APP_GROUP}}/" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./../static/img/grype.png" style="padding-right: 2px;padding-left: 3px;" height="50" width="50" alt="{{GRYPE_VERSION}}"></a>
          <div>
            <h5 class="mt-0 mb-1">Grype <a href="https://github.com/anchore/grype" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{GRYPE_VERSION}}</a> and Syft <a href="https://github.com/anchore/syft" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SYFT_VERSION}}</a></h5>
            Identifies known security vulnerabilities in application binaries and code. (<a href="{{GRYPE_REPORT_DIR}}/" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{GRYPE_REPORT_DIR}}/../13__GRYPE.log" rel="noreferrer" target="_blank" class="report-link">log</a>)
          </div>
      </div>
    </div>
  </div>

  <div class="container">
    <nav aria-label="breadcrumb">
      <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="./../security.html">Security</a></li>
        <li class="breadcrumb-item active">Grype</li>
        <li class="breadcrumb-item">{{APP}}</li>
      </ol>
    </nav>
  </div>

  <div class="container">
    <div class="row">
      <p></p>
    </div>
    <div class="row">
      <p>No vulnerability found while analyzing <span class="text-bold">{{APP}}</span> with <span class="text-bold">Grype</span>.</p>
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
              <a href="https://www.vmware.com/" rel="noreferrer" target="_blank"><img class="mr-3 me-2 vmware-logo" src="./../static/img/vmware.svg" alt="VMware"/></a>
              Generated with
              <a href="{{NAV_LINK}}" class="text-xxss text-black mb-3 ml-lg-3" rel="noreferrer" target="_blank">Application Portfolio Auditor</a>
              v.{{TOOL_VERSION}} from
              <a href="https://tanzu.vmware.com/labs" class="text-xxss text-black mb-3 ml-lg-3" aria-label="VMware Tanzu Labs" title="VMware Tanzu Labs" rel="noreferrer" target="_blank">VMware Tanzu Labs</a>
              on {{REPORT_TIMESTAMP}}</span>
          </div>
          <div class="footer-links mt-3">
              <span class="mb-3">&#169; 2023 VMware, Inc.</span>
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

</body>
</html>
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
    div#tools.bd-masthead.py-3.mb-3 { padding-bottom: 0rem !important; padding-top: 0.3rem !important; }
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
    .link {
      color: #212529;
    }
    h4.panel-title.panel-heading {
      -moz-box-sizing: border-box;
      -webkit-box-sizing: border-box;
      box-sizing: border-box;
    }
    section {
      margin: 0 auto;
    }
    .wrapper {
      min-height: 150px;
      position: relative;
      margin-bottom: 10px;
      margin-right: 10%;
      padding: 15px 15px 0px 25px;
    }
    .wrapper.cloud{
      border: 2px solid hsl(198, 100%, 28%);
      border-left: 40px solid hsl(198, 100%, 28%);
    }
    .wrapper.security{
      border: 2px solid hsl(9, 100%, 30%);
      border-left: 40px solid hsl(9, 100%, 30%);
    }
    .wrapper.quality{
      border: 2px solid hsl(93, 100%, 26%);
      border-left: 40px solid hsl(93, 100%, 26%);
    }
    .wrapper h3 {
      font-size: 1rem;
      color: white;
      text-transform: uppercase;
      letter-spacing: 3px;
      position: absolute;
      top: 0%;
      left: 0;
      margin-left: -10px;
      margin-top: 20px;
      -webkit-transform: rotate(90deg);
      -moz-transform: rotate(90deg);
      -ms-transform: rotate(90deg);
      -o-transform: rotate(90deg);
      transform: rotate(90deg);
      -webkit-transform-origin: 0 0;
      -moz-transform-origin: 0 0;
      -ms-transform-origin: 0 0;
      -o-transform-origin: 0 0;
      transform-origin: 0 0;
    }
    .wrapper h3 a {
      text-decoration: none;
      color: white;
    }
  </style>
</head>

<body>
  <!-- Header -->
  <header class="navbar navbar-expand navbar-dark flex-column flex-md-row bd-navbar">
    <div class="container">
      <a class="navbar-brand mr-0 me-md-2" href="./index.html"><img class="mr-3 me-3 filter-white company-logo" src="./static/img/company.svg" alt="VMware"/>Application Portfolio Auditor</a>
      <ul class="navbar-nav bd-navbar-nav justify-content-end">
        <li class="nav-item"><a class="nav-link active" href="#">Overview</a></li>
        {{#HAS_CLOUD_REPORT}}<li class="nav-item"><a class="nav-link" href="./cloud{{GROUP_POSTFIX}}.html">Cloud</a></li>{{/HAS_CLOUD_REPORT}}
        {{#HAS_SECURITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./security{{GROUP_POSTFIX}}.html">Security</a></li>{{/HAS_SECURITY_REPORT}}
        {{#HAS_QUALITY_REPORT}}<li class="nav-item"><a class="nav-link" href="./quality{{GROUP_POSTFIX}}.html">Quality</a></li>{{/HAS_QUALITY_REPORT}}
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
      <h1 class="display-4 mt-4 mb-2">Reports overview</h1>
      <div>
        <p class="lead mb-3 text-black-50">Consolidated list of all generated reports for the <span class="badge bg-dark">{{APP_GROUP}}</span> application group. (<a href="{{CSV_URL}}" rel="noreferrer" target="_blank" class="link">csv</a>)</p>
      </div>
    </div>
  </div>

  <!-- Header -->
  <div class="bd-masthead py-3 mb-3" id="tools" role="main">
    <div class="container">
      <div class="panel-group">
        <div class="panel panel-default">
          <div class="panel-heading">
            <h4 class="panel-title panel-heading">
              <span class="panel-heading">
                <span class="badge bg-dark">{{APP_COUNT}}</span> app{{#HAS_MULTIPLE_APPS}}s{{/HAS_MULTIPLE_APPS}} analyzed by <span class="badge bg-dark">{{TOOLS_COUNT}}</span> analysis tool{{#HAS_MULTIPLE_TOOLS}}s{{/HAS_MULTIPLE_TOOLS}}
              </span>
            </h4>
          </div>
        </div>
      </div> 
    </div> 
  </div>

  <!-- Tools -->
  <div class="container">
{{#HAS_INDEX_CLOUD_REPORT}}
    <div class="wrapper cloud">
      <h3><a style="display:inline-block" href="./cloud{{GROUP_POSTFIX}}.html">Cloud-Readiness</a></h3>
      <ul class="list-unstyled">
{{#HAS_CSA_REPORT}}
        <li class="d-flex">
          <a href="{{CSA_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/csa.svg" height="50" width="50" alt="Cloud Suitability Analyzer"></a>
          <div>
            <h5 class="mt-0 mb-1">Cloud Suitability Analyzer (CSA) <a href="https://github.com/vmware-tanzu/cloud-suitability-analyzer" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{CSA_VERSION}}</a></h5>
            Cloud readiness assessment with support for prioritization. (<a href="{{CSA_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{CSA_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_CSA_REPORT}}
{{#HAS_WINDUP_OR_PACKAGES_REPORT}}
        <li class="d-flex">
          <a href="{{#HAS_WINDUP_REPORT}}{{WINDUP_URL}}{{/HAS_WINDUP_REPORT}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/windup.png" height="50" width="50" alt="Windup"></a>
          <div>
            <h5 class="mt-0 mb-1">Windup <a href="https://github.com/windup/windup" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{WINDUP_VERSION}}</a></h5>
            Detection of proprietary code, dependencies, and technologies. ({{#HAS_WINDUP_REPORT}}<a href="{{WINDUP_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{WINDUP_CSV_ALL}}" rel="noreferrer" target="_blank" class="report-link">csv</a> - {{/HAS_WINDUP_REPORT}}{{#HAS_WINDUP_PACKAGES_REPORT}}<a href="{{WINDUP_PACKAGES}}" rel="noreferrer" target="_blank" class="report-link">packages</a>{{#HAS_WINDUP_REPORT}} - {{/HAS_WINDUP_REPORT}}{{/HAS_WINDUP_PACKAGES_REPORT}}{{#HAS_WINDUP_REPORT}}<a href="{{WINDUP_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>{{/HAS_WINDUP_REPORT}})
            <br/><br/>
          </div>
        </li>
{{/HAS_WINDUP_OR_PACKAGES_REPORT}}
{{#HAS_WAMT_REPORT}}
        <li class="d-flex">
          <a href="{{WAMT_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/ibm.jpg" height="50" width="50" alt="IBM WebSphere Application Migration Toolkit"></a>
          <div>
            <h5 class="mt-0 mb-1">IBM WebSphere Application Migration Toolkit (WAMT) <a href="https://www.ibm.com/support/pages/websphere-application-server-migration-toolkit" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{WAMT_VERSION}}</a></h5>
            Identifies required changes for IBM WebSphere migrations. (<a href="{{WAMT_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{WAMT_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_WAMT_REPORT}}
      </ul>
    </div>
{{/HAS_INDEX_CLOUD_REPORT}}
{{#HAS_SECURITY_REPORT}}
    <div class="wrapper security">
      <h3><a href="./security{{GROUP_POSTFIX}}.html">Security</a></h3>
      <ul class="list-unstyled">
{{#HAS_ODC_REPORT}}
        <li class="d-flex">
          <a href="{{ODC_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/owasp.svg" height="50" width="50" alt="Open Web Application Security Project Dependency-Check"></a>
          <div>
            <h5 class="mt-0 mb-1">Open Web Application Security Project (OWASP) Dependency-Check <a href="https://www.owasp.org/index.php/OWASP_Dependency_Check" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{OWASP_DC_VERSION}}</a></h5>
            Identifies well-known security vulnerabilities in embedded libraries. (<a href="{{ODC_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{ODC_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_ODC_REPORT}}
{{#HAS_FSB_REPORT}}
        <li class="d-flex">
          <a href="{{FSB_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/fsb.png" height="50" width="50" alt="Find Security Bugs"></a>
          <div>
            <h5 class="mt-0 mb-1">Find Security Bugs (FSB) <a href="https://find-sec-bugs.github.io/" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{FSB_VERSION}}</a></h5>
            Audits security of Java applications. (<a href="{{FSB_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{FSB_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_FSB_REPORT}}
{{#HAS_SLSCAN_REPORT}}
        <li class="d-flex">
          <a href="{{SLSCAN_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/scan-light.png" height="50" width="50" alt="ShiftLeft SAST Scan"></a>
          <div>
            <h5 class="mt-0 mb-1">ShiftLeft SAST Scan <a href="https://github.com/ShiftLeftSecurity/sast-scan" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SLSCAN_VERSION}}</a></h5>
            Identifies security vulnerabilities focussing on the <a href="https://owasp.org/www-project-top-ten/" rel="noreferrer" target="_blank" class="link">OWASP Top 10</a>. (<a href="{{SLSCAN_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{SLSCAN_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_SLSCAN_REPORT}}
{{#HAS_INSIDER_REPORT}}
        <li class="d-flex">
          <a href="{{INSIDER_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/insider.png" height="50" width="50" alt="Insider SAST"></a>
          <div>
            <h5 class="mt-0 mb-1">Insider SAST <a href="https://github.com/insidersec/insider" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{INSIDER_VERSION}}</a></h5>
            Identifies locally various kinds of security issues in application code. (<a href="{{INSIDER_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{INSIDER_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_INSIDER_REPORT}}
{{#HAS_GRYPE_REPORT}}
        <li class="d-flex">
          <a href="{{GRYPE_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/grype.png" height="50" width="50" alt="Grype"></a>
          <div>
            <h5 class="mt-0 mb-1">Grype <a href="https://github.com/anchore/grype" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{GRYPE_VERSION}}</a> and Syft <a href="https://github.com/anchore/syft" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SYFT_VERSION}}</a></h5>
            Identifies known security vulnerabilities in application binaries and code. (<a href="{{GRYPE_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{GRYPE_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_GRYPE_REPORT}}
{{#HAS_TRIVY_REPORT}}
        <li class="d-flex">
          <a href="{{TRIVY_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/trivy.svg" height="50" width="50" alt="Trivy"></a>
          <div>
            <h5 class="mt-0 mb-1">Trivy <a href="https://github.com/aquasecurity/trivy" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{TRIVY_VERSION}}</a></h5>
            Find vulnerabilities, misconfigurations, secrets. (<a href="{{TRIVY_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{TRIVY_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_TRIVY_REPORT}}
{{#HAS_OSV_REPORT}}
        <li class="d-flex">
          <a href="{{OSV_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/osv.png" height="50" width="50" alt="OSV"></a>
          <div>
            <h5 class="mt-0 mb-1">OSV <a href="https://github.com/google/osv.dev" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{OSV_VERSION}}</a></h5>
            Find vulnerable dependencies according to the OSV database. (<a href="{{OSV_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{OSV_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_OSV_REPORT}}
      </ul>
    </div>
{{/HAS_SECURITY_REPORT}}

{{#HAS_QUALITY_OR_LANGUAGE_REPORT}}
<div class="wrapper quality">
    <h3><a href="{{#HAS_QUALITY_REPORT}}./quality{{GROUP_POSTFIX}}.html{{/HAS_QUALITY_REPORT}}">Quality</a></h3>
      <ul class="list-unstyled">
{{#HAS_ARCHEO_REPORT}}
        <li class="d-flex">
          <a href="{{ARCHEO_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/archeo.png" height="50" width="50" alt="Archeo"></a>
          <div>
            <h5 class="mt-0 mb-1">Archeologist <a href="https://github.com/vmware-tanzu/application-portfolio-auditor" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{TOOL_VERSION}}</a></h5>
            Find unsupported and unnecessary ancient libraries in your applications. (<a href="{{ARCHEO_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{ARCHEO_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_ARCHEO_REPORT}}
{{#HAS_PMD_REPORT}}
        <li class="d-flex">
          <a href="{{PMD_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/pmd.png" width="50" alt="PMD Source Code Analyzer"></a>
          <div>
            <h5 class="mt-0 mb-1">PMD Source Code Analyzer <a href="https://pmd.github.io/" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{PMD_VERSION}}</a></h5>
            Extensible cross-language static code analyzer. (<a href="{{PMD_URL}}/pmd" rel="noreferrer" target="_blank" class="report-link">flaw</a> & <a href="{{PMD_URL}}/cpd" rel="noreferrer" target="_blank" class="report-link">copy-paste</a> reports - <a href="{{PMD_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_PMD_REPORT}}
{{#HAS_SCANCODE_REPORT}}
        <li class="d-flex">
          <a href="{{SCANCODE_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/scancode.png" height="50" width="50" alt="ScanCode Toolkit"></a>
          <div>
            <h5 class="mt-0 mb-1">ScanCode Toolkit <a href="https://github.com/nexB/scancode-toolkit" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{SCANCODE_VERSION}}</a></h5>
            Detect licenses, copyrights, and package manifests of embedded libraries. (<a href="{{SCANCODE_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{SCANCODE_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_SCANCODE_REPORT}}
{{#HAS_MAI_REPORT}}
        <li class="d-flex">
          <a href="{{MAI_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/microsoft.png" height="50" width="50" alt="Microsoft Application Inspector"></a>
          <div>
            <h5 class="mt-0 mb-1">Microsoft Application Inspector <a href="https://github.com/Microsoft/ApplicationInspector" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{MAI_VERSION}}</a></h5>
            Identify what is in the applications using static analysis. (<a href="{{MAI_URL}}" rel="noreferrer" target="_blank" class="report-link">reports</a> - <a href="{{MAI_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_MAI_REPORT}}
{{#HAS_LANGUAGES_REPORT}}
        <li class="d-flex">
          <a href="{{LANGUAGES_URL}}" rel="noreferrer" target="_blank"><img class="mr-3 me-3" src="./static/img/github.svg" height="50" width="50" alt="GitHub Linguist and CLOC"></a>
          <div>
            <h5 class="mt-0 mb-1">GitHub Linguist <a href="https://github.com/github/linguist" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{LINGUIST_VERSION}}</a> and CLOC <a href="https://github.com/AlDanial/cloc" rel="noreferrer" target="_blank" class="badge bg-light text-dark">v.{{CLOC_VERSION}}</a></h5>
            Analyze language usage and generate language breakdown graphs. (<a href="{{LANGUAGES_URL}}" rel="noreferrer" target="_blank" class="report-link">report</a> - <a href="{{LANGUAGES_LOG}}" rel="noreferrer" target="_blank" class="report-link">log</a>)
            <br/><br/>
          </div>
        </li>
{{/HAS_LANGUAGES_REPORT}}
      </ul>
    </div>
{{/HAS_QUALITY_OR_LANGUAGE_REPORT}}
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
</body>
</html>

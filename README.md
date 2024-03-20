# Application Portfolio Auditor

`Application Portfolio Auditor` is an open-source assessment tool that automates and simplifies the audit of large sets of applications. By leveraging up to 18 analysis tools, it generates comprehensive reports helping you to quickly gain insights on your applications and build an effective application modernization roadmap.

Key features:

- **Comprehensive CLI**: The `audit` Command Line Interface (CLI) lowers the barriers to reliably analyze a large set of applications.

- **Hardened by default**: Systematically validates prerequisites and pre-configures analysis tools following best practices.

- **Wide variety of applications supported**: Covers most modern programming languages (Java, Python, .NET, NodeJS) and analyzes as well source code as compiled binaries.

- **Combined intelligence:** Harnesses and combines insights of up to 15 free and open-source application analysis tools.

- **Aggregated summaries**: Generates static HTML pages connecting all results to help you understand your portfolio from different perspectives such as cloud-readiness, security, languages used, licensing, and quality.

- **Portable results**: Exports reports as exploded directory, ZIP files, Kubernetes or Cloud-Foundry deployments.

## Getting Started

Follow these steps to get started with `Application Portfolio Auditor`:

1. Clone the repository:
```bash
$ git clone git@github.com:vmware-tanzu/application-portfolio-auditor.git
```

2. Install prerequisites:
```bash
$ cd application-portfolio-auditor
$ ./audit setup
```
> Note: This command automates the installation of all required prerequisites. It automatically configures based on the detected operating system (MacOS, Ubuntu, or CentOS) and requires sudo rights. The process may take several minutes to complete.

> Hint: If you are experiencing issues during the installation, please make sure that your local user has full access to the installation folder: `$ sudo chown -R $(id -u):$(id -g) "application-portfolio-auditor"`

3. Retrieve necessary tools and frameworks:
```bash
$ ./audit download
```
> Note: This command downloads the required resources from the Internet and builds multiple Docker images locally. The process may take several minutes to complete.

4. Generate your first report:
   1. Download a test application: `mkdir -p apps/test; wget -P apps/test https://repo1.maven.org/maven2/org/codehaus/cargo/simple-ear/1.10.9/simple-ear-1.10.9.ear`
   2. Start the analysis `./audit run -a -g test`
   3. Open the `index.html` file in the created `reports/TIMESTAMP` directory to view the generated reports.
   4. Start the [Cloud Suitability Analyzer](https://github.com/vmware-tanzu/cloud-suitability-analyzer) backend by executing `./launch_csa_ui.sh` in the `reports/TIMESTAMP` directory. All other reports are static files.
   5. Explore the reports, findings, and tool capabilities!


## Frequently Asked Questions

<!-- faq 1 -->
<details>
<summary>What are the technical <b>prerequisites</b> to run the tool?</summary>
<br/>
This table summarizes all prerequisites to use Application Portfolio Auditor:

|  Category | Mininum | Recommended |
| ------------- | ------------- | ------------- |
| Operating System  | CentOS, Ubuntu or MacOS | Latest version installed | 
| RAM  | 16+ GB | 32 GB |
| Disk  | 100+ GB | SSD disk |
| CPU  | 8+ Cores / vCPUs  | - |
| Chips  | Intel or Apple silicon | - |
| Internet  | Available for setup and updates | Available during the analysis |
</details>

<!-- faq 2 -->
<details>
<summary>What <b>types of applications</b> can be analyzed?</summary>
<br/>
Most modern application implemented leveraging modern programming languages are supported (Java, Python, .NET, NodeJS). As well binaries as source code can be analyzed.
</details>

<!-- faq 3 -->
<details>
<summary>Where can I learn more and find the <b>documentation</b>?</summary>
<br/>
Please check the <a href="https://github.com/vmware-tanzu/application-portfolio-auditor/blob/main/doc/ABOUT.md">ABOUT.md</a> page.
</details>

<!-- faq 4 -->
<details>
<summary>I have an issue, what should I do?</summary>
<br/>
First, make sure that you are meeting all prerequisites. Especially ensure you have enough RAM allocated to your docker environment.

If a restart, some cleanup or a glance at the documentation does not further helps, you can <a href="https://github.com/vmware-tanzu/application-portfolio-auditor/issues/new/choose">create</a> an issue on GitHub. For specifics on what to include in your report, please follow the pull request guidelines above and share:
<ul>
  <li>What happened: Also tell us, what did you expect to happen.</li>
  <li>Version used: What version of application-portfolio-auditor are you running.</li>
  <li>Environment: What Operating System, Chip (Intel/Apple Silicon) is the software running on.</li>
  <li>Any other potentially relevant information like the browser of JDK used.</li>
</ul>
</details>


## Contributing

The Application Portfolio Auditor project team welcomes contributions from the community. If you wish to contribute code and you have not signed our [Contributor License Agreement](https://cla.vmware.com/cla/1/preview), our bot will update the issue when you open a Pull Request. For any questions about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq). For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).


## License

Application Portfolio Auditor is released under the Apache License 2.0. For more detailed information, please refer to the [LICENSE](LICENSE) file.

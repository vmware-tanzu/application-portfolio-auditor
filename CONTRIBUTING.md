# Contributing to application-portfolio-auditor

We welcome contributions from the community and first want to thank you for taking the time to contribute!

Please familiarize yourself with the [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

Before you start working with application-portfolio-auditor, please read and sign our Contributor License Agreement [CLA](https://cla.vmware.com/cla/1/preview). If you wish to contribute code and you have not signed our contributor license agreement (CLA), our bot will prompt you to do so when you open a Pull Request. For any questions about the CLA process, please refer to our [FAQ]([https://cla.vmware.com/faq](https://cla.vmware.com/faq)).

## Ways to contribute

We welcome many different types of contributions and not all of them need a Pull request. Contributions may include:

* New features and proposals
* Documentation
* Bug fixes
* Issue Triage
* Answering questions and giving feedback
* Helping to onboard new contributors
* Other related activities

## Contribution Flow

This is a rough outline of what a contributor's workflow looks like:

``` shell
# Make a fork of the repository within your GitHub account
git remote add upstream https://github.com/vmware-tanzu/application-portfolio-auditor.git
# Create a topic branch in your fork from where you want to base your work
git checkout -b my-custom-new-feature master
# Make commits of logical units and check that your commit messages are with the proper format, quality, and descriptiveness (see below)
git commit -a
# Push your changes to the topic branch in your fork
git push origin my-custom-new-feature
```
Then create a pull request containing that commit.

## Creating a Pull Request

We follow the GitHub workflow and you can find more details on the [GitHub flow documentation](https://docs.github.com/en/get-started/quickstart/github-flow).

Before submitting your pull request, we advise you to use the following:

1. Test if your code changes affect generated reports for several applications as expected.
2. Ensure your commit messages are descriptive. We follow the conventions on [How to Write a Git Commit Message](http://chris.beams.io/posts/git-commit/).
3. Be sure to include any related GitHub issue references in the commit message (if any). See [GFM syntax](https://guides.github.com/features/mastering-markdown/#GitHub-flavored-markdown) for referencing issues and commits.
3. Check the commits and commits messages and ensure they are free from typos.


### Updating Your Pull Request

If your pull request (PR) needs changes, you'll most likely want to squash these changes into existing commits.

``` shell
git add .
git commit --fixup <commit>
git rebase -i --autosquash master
git push --force-with-lease origin my-custom-new-feature
```

If your pull request contains a single commit or your changes are related to the most recent commit, you can simply amend the commit.

``` shell
git add .
git commit --amend
git push --force-with-lease origin my-custom-new-feature
```

Be sure to add a comment to the PR indicating your new changes are ready to review, as GitHub does not generate a notification when you git push.


## Reporting Bugs and Creating Issues

For specifics on what to include in your report, please follow the pull request guidelines above and share:
* What happened: Also tell us, what did you expect to happen.
* Version used: What version of application-portfolio-auditor are you running.
* Environment: What Operating System, Chip (Intel/Apple Silicon) is the * software running on.
* Any other potentially relevant information like the browser of JDK used.

## Ask for Help

The best way to reach us with a question when contributing is to ask on the original GitHub issue.


## Additional Resources

* Cloud-readiness
    * [Cloud Suitability Analyzer](https://github.com/vmware-tanzu/cloud-suitability-analyzer/)
    * [Windup](https://github.com/windup/windup)
    * [IBM WAMT](https://www.ibm.com/support/pages/websphere-application-server-migration-toolkit))

* Security
    * [OWASP Dependency-Check](https://www.owasp.org/index.php/OWASP_Dependency_Check)
    * [Find Security Bugs](https://find-sec-bugs.github.io/)
    * [Insider SAST](https://github.com/insidersec/insider)
    * [ShiftLeft SAST Scan](https://github.com/ShiftLeftSecurity/sast-scan)
    * [Syft](https://github.com/anchore/syft)
    * [Grype](https://github.com/anchore/grype)
    * [Trivy](https://github.com/aquasecurity/trivy)) 

* Quality
    * [PMD](https://pmd.github.io/)
    * [ScanCode Toolkit](https://github.com/nexB/scancode-toolkit)
    * [Microsoft Application Inspector](https://github.com/Microsoft/ApplicationInspector))

* Distribution of languages
    * [GitHub Linguist](https://github.com/github/linguist)
    * [CLOC](https://github.com/AlDanial/cloc))
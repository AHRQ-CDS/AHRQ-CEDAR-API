Contributing
============

Thank you for your interest in contributing to the open source CEDAR
project! We welcome all friendly contributions, including:

- Bug reports
- Comments and suggestions
- Feature requests
- Bug fixes
- Feature implementations and enhancements
- Documentation updates and additions

To ensure a welcoming environment, we follow the [Contributor Covenant
Code of Conduct](CODE-OF-CONDUCT.md) and expect contributors to do the
same.

Before making a contribution, please familiarize yourself with this
document, the project [README](README.md), and the CEDAR
[Terms and Conditions](TERMS-AND-CONDITIONS.md).

Issues
------

We use GitHub issues to track bug reports, comments, suggestions,
questions, and feature requests.

Before submitting a new issue, please check to make sure a similar issue
isn't already open. If one is, contribute to that issue thread with your
feedback.

When submitting a bug report, please try to provide as much detail as
possible. This may include:

- Steps to reproduce the problem
- Screenshots demonstrating the problem
- The full text of error messages
- Relevant outputs
- Any other information you deem relevant

Please note that the GitHub issue tracker is *public*; any issues you
submit are immediately visible to everyone. For this reason, do *not*
submit any information that may be considered sensitive.

Code Contributions
------------------

If you are planning to work on a reported bug, suggestion, or feature
request, please comment on the relevant issue to indicate your intent to
work on it. If there is no associated issue, please submit a new issue
describing the feature you plan to implement or the bug you plan to fix.
This reduces the likelihood of duplicated effort and also provides the
maintainers an opportunity to ask questions, provide hints, or indicate
any concerns *before* you invest your time.

### Coding Practices

Code that is contributed to this project should follow these practices:

- Make changes in a personal
  [fork](https://help.github.com/articles/fork-a-repo/) of this
  repository
- Use descriptive commit messages, referencing relevant issues as
  appropriate (e.g., "Fixes \#555: Update component to...")
- Follow the styles and conventions as enforced by the lint
  configurations and as evidenced by the existing code
- Prefer self-explanatory code as much as possible, but provide
  helpful comments for complex expressions and code blocks
- Ensure any user-facing components are accessible (i.e., compliant
  with [Section 508](https://www.section508.gov/))
- Include unit tests for any new or changed functionality
- Update documentation to reflect any user-facing changes

### Before Submitting a Pull Request

Before submitting a Pull Request for a code contribution:

- [Rebase](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) on
  master if your code is out of synch with master
  - If you need help with this, submit your Pull Request without
    rebasing and indicate you need help
- Build the code (if applicable) and ensure there are no new warnings
  or errors
- Run the tests and ensure that all tests pass
- Run the linter and ensure that there are no linter warnings or
  errors

For details on how to build, test, and lint, see the project README
file.

### Submitting a Pull Request

Pull requests should include a summary of the work, as well as any
specific guidance regarding how to test or invoke the code.

When project maintainers review the pull request, they will:

- Verify the contribution is compatible with the project's goals and
  mission
- Run the project's unit tests and linters to ensure there are no
  violations
- Deploy the code locally to ensure it works as expected
- Review all code changes in detail, looking for:
  - Potential bugs, regressions, security issues, or unintended
    consequences
  - Edge cases that may not be properly handled
  - Application of generally accepted best practices
  - Adequate unit tests and documentation

### If the Pull Request Passes Review

Congratulations! Your code will be merged by a maintainer into the
project's master branch!

### If the Pull Request Does Not Pass Review

If the review process uncovers any issues or concerns, a maintainer will
communicate them via a Pull Request comment. In most cases, the
maintainer will also suggest changes that can be made to address those
concerns and eventually have the Pull Request accepted. If this happens:

- Address any noted issues or concerns
- Rebase (if necessary) and push your code again (may require a force
  push if you rebased)
- Comment on the Pull Request indicating it is ready for another
  review

Apache 2.0
----------

All contributions to this project will be released under the [Apache 2.0
license](http://www.apache.org/licenses/LICENSE-2.0). By submitting a
pull request, you are agreeing to comply with this license. As indicated
by the license, you are also attesting that you are the copyright owner,
or an individual or Legal Entity authorized to submit the contribution
on behalf of the copyright owner.

# KAZOO Pull Request Checklist

## General PR checklist

* [ ] Have you run the CI checks locally and addressed any issues found? `make ci-codechecks ci-docs` are typical targets to run
* [ ] Have you dialyzed the code and the types? `make dialyze-hard` and `make dialyze-types`
* [ ] Have you rebased your branch against the latest primary branch (`master`) or version branch (`5.1` for instance) if this is a bug PR?
* [ ] Have you squashed your commits into a single commit (with appropriate title/description) for the initial opening of the PR?

## Helpful PR topics to cover

* [ ] What audience is impacted by this PR? Operations? API developers? Sales?
* [ ] What steps are needed to be taken to take advantage of this PR? SUP commands, system config updates, etc

## Feature PRs

For pull requests adding features to the primary branch (`master` in most cases):

* [ ] Is the Pull Request title of the format `{TICKET_NUMBER} - Short Description`?
      For example: `KZOO-555: Add ability to format caller ID`
* [ ] Is the Pull Request description useful? Is the context of why the feature PR has been opened clear?
* [ ] Is there a test related to the functionality, and is it included in the PR or a linked repository's PR?

## Bug Fix PRs

For pull requests fixing bugs:

* [ ] Is a PR opened for the primary branch (`master`) and named `{TICKET_NUMBER} - Short Description`?
* [ ] Is a PR opened on each version branch (`5.1` for instance) where the bug is prenset?
  * [ ] Is the PR title formatted as `[{VERSION}] {TICKET_NUMBER} - Short Description`? For instance `[5.1] KZOO-556: fix delay when sending AMQP payload`
* [ ] Does the PR's description describe what the behaviour was before the PR that required a change?
* [ ] Does the PR's description describe what the fix does to address the invalid behaviour going forward?

# Contribution Assessment Plan

## The Purpose of this Document:
In order to expedite PR review and approval processes, and to remove workload from Tanner, the members of the #contributors channel assemble this document to detail new processes around the Vapor project.

## Ownership:
Each core repo will have at least one member as “expert” or “owner”. They will be in charge of understanding the inner workings of their repo and maintaining the quality of their repo via code review and feedback to potential contributors. Some repos may not have any current experts. In such cases, a volunteer will be assigned to that repo, and approval of any PRs to that repo will require (disproportionally more reviewers + the owner || Tanner + the owner). Over time, the assigned expert will feel more comfortable in their area, at which point they can reduce the required number of reviewers or Tanner will no longer be required to review alongside them.

## Owner Responsibilities:
Each Owner will be responsible for keeping up with PRs and issues for their repo. It is recommended that they follow their repo on Github and unfollow others if necessary to keep relevant notifications visible. 

In addition to having familiarity with their repo, they should also familiarize themselves with the relevant portion of the tutorial-style docs so they know when updates need to be made in tandem with an incoming PR.

## PR Rules:
All agreed upon rules will be included in PR templates.

PRs must exist for at least 24 hours before they are accepted. This is to allow time for contributors from every time zone to review the PR if they wish.

## Bug Fixes:
All bug fixes will require updated tests to catch the case that’s being fixed. Newer contributors who aren’t used to testing may need some guidance.
If an expert notes that an incoming bugfix is indicative of the need for a larger refactor, note it in the comments, accept the PR anyway, and then open up a new PR for the refactor. 

## Public API Changes:
Public API Changes will likely require updates to both tutorial docs and API docs. Experts may want to either guide contributors to make these updates and then act as editor afterwards, or make these updates for them, especially in cases where the contributor’s English isn’t the best. Poor documentation wording should not block acceptance of a PR. We don’t want to discourage code contributions from folks with English as their second language.

Because Vapor follows semantic versioning, the owner of a repo will make sure no breaking changes are merged for minor releases. A breaking change is when an update to the API will cause a compiler error to occur where code originally compiled (with or without warnings).
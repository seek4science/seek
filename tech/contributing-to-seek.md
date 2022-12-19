---
title: contributing to seek
layout: page
redirect_from: "/contributing-to-seek.html"
---

# Contributing to SEEK

We welcome all sorts of contributions to SEEK,

* **Non-developer contributions.** These are contributions that can be made by anyone
  using SEEK.
  * *Vote and comment other feature requests:* [Contact us](/contacting-us.html) please use the [SEEK issue tracker](http://fair-dom.org/issues). 
  * *Documentation:* Are you reading the documentation and feel something could/should be better explained? Please read [Contributing to these Pages](/contributing-to-pages.html)
  * *Reporting errors:* We are also thankful if you spot errors or broken links.
* **Developer contributions** These are contributions that can be made by other software
  developers.
  * *Code tidying & bug fixes:* Refactoring to improve quality is always welcome and a good way of starting contributing.
  * *New features, major improvements, new subsystems:* All of these need communication to check if they can be built in without breaking other efforts.

## Before you start

Always read [Report bugs and new features](reporting-bugs-and-features.html) before you start, and contact us.
It is possible the feature is already being looked at by another contributor and effort could be combined.


## Changing and contributing code

The SEEK source code is available on GitHub at [https://github.com/seek4science/seek](https://github.com/seek4science/seek)

The easiest way to contribute code (for both us and you) is to do so through GitHub. You can do so by creating a forked repository. Make you changes on a branch within your forked repository.

Once you have finished making your changes and wish to contribute them, you can do so by issuing a pull request.

If contributing through GitHub is unfamiliar to you, please read [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)

For small changes emailing a patch file may be suitable.

## Quality control

For a contribution to be accepted, we do have a few requirements.

  * Code should follow the [Ruby Style Guidelines](https://github.com/bbatsov/ruby-style-guide). Our gems include the tool [Rubocop](https://github.com/bbatsov/rubocop), which can be used to check against the guidelines and (with care) automatically fix some issues.
  * Where practical, tests should be added to cover your changes, and all existing tests should pass. The continuous integration tool: [Travis](https://travis-ci.org/seek4science/seek) is useful to checking your tests as your work. _Be pragmatic, don't spend 2 days writing tests for a 5 minute 2 line fix!_
  * Code should be clear, and in some cases we may request some documentation.

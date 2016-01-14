---
title: contributing to seek
layout: page
redirect_from: "/contributing-to-seek.html"
---
#Contributing to SEEK

We welcome all sorts of contributions to SEEK, from a small spelling fix, code tidying, a bug fix to major improvement or new feature.

##Before you start

If you are interesting contributing, please first look at our [JIRA issue tracker](https://jira-bsse.ethz.ch/browse/OPSK), either to find something you can contribute, or whether your
idea already exists. **Before starting** you should also always [Contact Us](/contacting-us.html) first - it is quite possible work is already in progress or we have ideas, and we wouldn't want your
effort to be wasted.

##Changing and contributing code

The SEEK source code is availale on GitHub at [https://github.com/seek4science/seek](https://github.com/seek4science/seek)

The easiest way to contribute code (for both us and you) is to do so through GitHub. You can do so by creating a forked repository. Make you changes on a branch within your forked repository.
For large changes you would be advised to link your repository to [Code Climate](https://codeclimate.com) and [Travis](https://travis-ci.org) (see below).

Once you have finished making your changes and wish to contribute them, you can do so by issuing a pull request.

If contributing through GitHub is unfamiliar to you, please read [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)

For small changes emailing a patch file may be suitable.

##Quality control

For a contribution to be accepted, we do have a few requirements.

  * Code should follow the [Ruby Style Guidelines](https://github.com/bbatsov/ruby-style-guide). Our gems include the tool [Rubocop](https://github.com/bbatsov/rubocop), which can be used to check against the guidelines and (with care) automatically fix some issues.
  * Where practical, tests should be added to cover your changes, and all existing tests should pass. The continuous integration tool: [Travis](https://travis-ci.org/seek4science/seek) is useful to checking your tests as your work. _Be pragmatic, don't spend 2 days writing tests for a 5 minute 2 line fix!_
  * We will check quality using [Code Climate](https://codeclimate.com/github/seek4science/seek) for complexity or duplication. You can use [Rubycritic](https://github.com/whitesmith/rubycritic) to check on your local machine.
  * Code should be clear, and in some cases we may request some documentation.

---
title: contributing to pages
layout: page
---

#Contributing to these pages

If you find a mistake or wish to make an improvement to these pages, you can do so. For a small mistake, just let us know by [contacting us](contacting_us.html). For other changes you can also access and edit the pages themself.

As well as the SEEK source code, these pages are also stored in GitHub at [https://github.com/seek4science/seek](https://github.com/seek4science/seek)
and served by [GitHub pages](https://pages.github.com/).

They are under the branch [_gh-pages_](https://github.com/seek4science/seek/tree/gh-pages). Pages are in [Markdown](https://help.github.com/articles/markdown-basics/) format, with a _.md_ extension, but get converted into HTML for you.
New pages require a formatter at the top, that looks like:

    ---
    title: my lovely page
    layout: page
    ---

For example, this page can be found at [https://raw.githubusercontent.com/seek4science/seek/gh-pages/contributing-to-pages.md](https://raw.githubusercontent.com/seek4science/seek/gh-pages/contributing-to-pages.md)

If you want to view your changes as you edit them, with Ruby and Bundler installed you can do:

    bundle install
    bundle exec jekyll serve

and then goto [localhost:4000/seek/](http://localhost:4000/seek/). For more information please see [Using Jekyll with Pages](https://help.github.com/articles/using-jekyll-with-pages/)

You can make a change by forking and issuing a pull request. Please read [how to contribute to open source projects on GitHub](https://gun.io/blog/how-to-github-fork-branch-and-pull-request/)
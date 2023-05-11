---
title: using Teaspoon
layout: page
redirect_from: "/using-teaspoon.html"
---

# Using Teaspoon

[Teaspoon](https://github.com/modeset/teaspoon) is a javascript test runner for Rails. You can use it to run tests in the browser or headless with PhantomJS, Selenium WebDriver or Capybara Webkit.
In SEEK, we use Teaspoon together with [Selenium WebDriver](https://rubygems.org/gems/selenium-webdriver).
 
To run Teaspoon in browser, start your rails server and access:
    
    http://localhost:3000/teaspoon
    
To run Teaspoon from rake task:

    RAILS_ENV=test bundle exec rake teaspoon

    
[Mocha](https://mochajs.org/) is used together with Teaspoon. Mocha is a javascript testing framework.
We integrate [Chai](http://chaijs.com/api/assert/) as the assertion library, and [Sinon](http://sinonjs.org/) for stubing/spying/mocking request

To write javascript test in SEEK, add your *_spec.js file under spec/javascripts folder.

You can find an example here: [upload_selection_spec.js](https://github.com/seek4science/seek/blob/main/spec/javascripts/upload_selection_spec.js)


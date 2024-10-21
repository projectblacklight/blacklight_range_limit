BlacklightRangeLimit:  integer range limiting and profiling for Blacklight applications

![Build Status](https://github.com/projectblacklight/blacklight/workflows/CI/badge.svg) [![Gem Version](https://badge.fury.io/rb/blacklight_range_limit.png)](http://badge.fury.io/rb/blacklight_range_limit)

![Screen shot](doc/example-screenshot.png)

# Description

The BlacklightRangeLimit plugin provides a 'facet' or limit for integer fields, that lets the user enter range limits with a text box or a slider, and also provides area charts giving a sense of the distribution of values (with drill down).

The primary use case of this plugin is for 'year' data, but it should work for any integer field. It may not work right for negative numbers, however.

Decimal numbers and Dates are NOT supported; they theoretically could be in the future, although it gets tricky.


# Requirements

* A Solr integer field. It might be advantageous to use an IntPointField.

* Javascript requires you to be using either rails-importmaps or a package.json-based builder like jsbundling-rails or vite-ruby.  Legacy "sprockets-only" is not supported.

* Blaklight 7+.  Rails 7.0+


# Installation

Add

    gem "blacklight_range_limit"

to your Gemfile. Run "bundle install".

Run `rails generate blacklight_range_limit:install`

# Configuration

You have at least one solr field you want to display as a range limit, that's why you've installed this plugin. In your CatalogController, the facet configuration should look like:

```ruby
config.add_facet_field 'pub_date', label: 'Publication Year', **default_range_config
```

You should now get range limit display. More complicated configuration is available if desired, see Range Facet Configuration below.

## A note on AJAX use

In order to calculate distribution segment ranges, we need to first know the min and max boundaries. But we don't really know that until we've fetched the result set (we use the Solr Stats component to get min and max with a result set).

So, ordinarily, after we've gotten the result set, an additional round trip to back-end and solr will happen, with min max identified, to fetch segments.

If you'd like to avoid this, you can turn off segment display altogether with the :segment option below; or you can set :assumed_boundaries below to use fixed boundaries for not-yet-limited segments instead of taking boundaries from the result set.

Note that a drill-down will never require the second request, because boundaries on a drill-down are always taken from the specified limits.


## Range Facet Configuration

Instead of simply passing "true", you can pass a hash with additional configuration. Here's an example with all the available keys, you don't need to use them all, just the ones you want to set to non-default values.

```ruby
config.add_facet_field 'pub_date', label: 'Publication Year',
                       range: {
                         num_segments: 6,
                         assumed_boundaries: [1100, Time.now.year + 2],
                         segments: false,
                         maxlength: 4
                       }
```

* **:num_segments** :
  * Default 10. Approximately how many segments to divide the range into for segment facets, which become segments on the chart. Actual segments are calculated to be 'nice' values, so may not exactly match your setting.
* **:assumed_boundaries** :
  * Default null. For a result set that has not yet been limited, instead of taking boundaries from results and making a second AJAX request to fetch segments, just assume these given boundaries. If you'd like to avoid this second AJAX Solr call, you can set :assumed_boundaries to a two-element array of integers instead, and the assumed boundaries will always be used. Note this is live ruby code, you can put calculations in there like Time.now.year + 2.
* **:segments** :
  * Default true. If set to false, then distribution segment facets will not be loaded at all.
* **:maxlength** :
  * Default 4. Changes the value of the `maxlength` attribute of the text boxes, which determines how many digits can be entered.

## Javascript dependencies

We use [chart.js](https://www.chartjs.org/) to draw the chart. It has one dependency of it's own. These need to be either pinned with importmap-rails, or used via the chart.js npm package and an npm-package-based bundler. The installer should take care of it.

# Tests

Test coverage is not great, but there are some tests, using rspec.  Run `bundle exec rake ci` or just `bundle exec rake` to seed and
start a demo jetty server, build a clean test app, and run tests.

Just `bundle exec rake spec` to just run tests against an existing test app and jetty server.

## Local Testing
If you want to iterate on a test locally and do not want to rebuild the
required test environment every time you run the test you can set up the
required server by first running:
```bash
bundle exec rake test:server
```

Now from another shell run your individual test as needed:
```bash
bundle exec rspec spec/features/blacklight_range_limit_spec.rb
```

Once you are done iterating on your test you will need to stop the application server with `Ctrl-C`.

# Publishing Javascript

run `npm publish` to push the javascript package to https://npmjs.org/package/blacklight-range-limit


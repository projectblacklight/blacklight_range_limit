BlacklightRangeLimit:  integer range limiting and profiling for Blacklight applications

[![Build Status](https://travis-ci.org/projectblacklight/blacklight_range_limit.png?branch=v5.0.0)](https://travis-ci.org/projectblacklight/blacklight_range_limit) [![Gem Version](https://badge.fury.io/rb/blacklight_range_limit.png)](http://badge.fury.io/rb/blacklight_range_limit)

![Screen shot](doc/example-screenshot.png)

# Description

The BlacklightRangeLimit plugin provides a 'facet' or limit for integer fields, that lets the user enter range limits with a text box or a slider, and also provides area charts giving a sense of the distribution of values (with drill down). 

The primary use case of this plugin is for 'year' data, but it should work for any integer field. It may not work right for negative numbers, however. 

Decimal numbers and Dates are NOT supported; they theoretically could be in the future, although it gets tricky. 


# Requirements

A Solr integer field. Depending on your data, it may or may not be advantageous to use a tint (trie with non-zero precision) type field. 

## Note on solr field types

If all your integers are the same number of digits, you can use just about any solr type, including string/type, and all will be well. But if your integers vary in digits, strings won't sort correctly, making your numbers behave oddly in partitions and limits. This is also true if you use a pre-1.4 "integer"/pint/solr.IntField  field -- these are not "sortable". 

You need to use a "sortable" numeric-type field. In Solr 1.4, the standard "int"/solr.TrieIntField should work fine and is probably prefered. For some distributions of data, it may be more efficient to use "tint" (solr.TrieIntField with non-zero precision). 

The pre Solr 1.4 now deprecated sint or slong types should work fine too. 

# Installation

Current 5.x version of `blacklight_range_limit` work with `blacklight` 5.x -- we now synchronize the _major version number_ between `blacklight` and `blacklight_range_limit`.  `blacklight_range_limit` 2.1 is the last version believed to work with blacklight 4.x or possibly blacklight 3.x.

Add

    gem "blacklight_range_limit"

to your Gemfile. Run "bundle install". 

Then run 

    rails generate blacklight_range_limit:install

This will install some asset references in your application.js and application.css.

# Configuration

You have at least one solr field you want to display as a range limit, that's why you've installed this plugin. In your CatalogController, the facet configuration should look like:

```ruby
config.add_facet_field 'pub_date', label: 'Publication Year', range: true 
```
  
You should now get range limit display. More complicated configuration is available if desired, see Range Facet Configuration below. 


You can also configure the look and feel of the Flot chart using the jQuery .data() method. On the `.facet_limit` container you want to configure, add a Flot options associative array (documented at http://people.iola.dk/olau/flot/API.txt) as the `plot-config` key. The `plot-config` key to set the `plot-config` key on the appropriate `.facet_limit` container. In order to customize the plot colors, for example, you could use this code:

```javascript
$('.blacklight-year_i').data('plot-config', { 
    selection: { color: '#C0FF83' }, 
    colors: ['#ffffff'], 
    series: { lines: { fillColor: 'rgba(255,255,255, 0.5)' }}, 
    grid: { color: '#aaaaaa', tickColor: '#aaaaaa', borderWidth: 0 }  
});
```
You can add this configuration in app/assets/javascript/application.js, or anywhere else loaded before the blacklight range limit javascript.

## A note on AJAX use

In order to calculate distribution segment ranges, we need to first know the min and max boundaries. But we don't really know that until we've fetched the result set (we use the Solr Stats component to get min and max with a result set). 

So, ordinarily, after we've gotten the result set, only then can we calculate the segment ranges, and then we need to do another Solr request to actually fetch the segment range counts. 

The plugin uses an AJAX request on the result page to do this. This means that for every application results display that includes any values at all in your range field, your application will get a second AJAX http request, and make a second solr request. 

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

The selectable histograms/barcharts are done with Javascript, using [Flot](http://code.google.com/p/flot/). Flot requires JQuery, as well as support for the HTML5 canvas element. In IE previous to IE9, canvas element support can be added with [excanvas](http://excanvas.sourceforge.net/). For the slider, [bootstrap-slider](http://www.eyecon.ro/bootstrap-slider/) is used (bootstrap-slider is actually third party, not officially bootstrap). Flot and bootstrap-slider are both directly included in blacklight_range_limit in vendor. 

A `require 'blacklight_range_limit'` in a Rails asset pipeline manifest file will automatically include all of these things. The blacklight_range_limit adds just this line to your `app/assets/application.js`. 

There is a copy of flot vendored in this gem for this purpose. jquery is obtained from the jquery-rails gem, which this gem depends on. 

Note this means a copy of jquery, from the jquery-rails gem, will be included in your assets by blacklight_range_limit even if you didn't include it yourself explicitly in application.js. Flot will also be included.

If you don't want any of this gem's JS, you can simply remove the `require 'blacklight_range_limit'` line from your application.js, and hack something else together yourself. 

## IE8, excanvas

IE8 and below do not support the 'canvas' element, needed for flot to render the chart. 
Without canvas, view will cleanly degrade to an ordinary textual listing of range segments
as facets. 

Or, you can use excanvas.js to add canvas support to IE.  `blacklight_range_limit` includes
the `excanvas.js` file, but you'll have to manually add a reference to it to your Rails layout
template -- if you were previously using the stock Blacklight layout, you'll have to add a
local custom layout instead. Then add this to the html `<head>` section:

    <!--[if lte IE 8]><%= javascript_include_tag 'flot/excanvas.min' %><![endif]-->

## Touch?

For touch screens, one wants the UI to work well. The slider used is
[bootstrap_slider](http://www.eyecon.ro/bootstrap-slider/), which says if you add
Modernizr to your page, touch events will be supported. We haven't tested it
ourselves yet. 

Also not sure how well the flot select UI works on a touch screen. The slider
is probably the best touch UI anyway, if it can be made to work well. 

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

# Possible future To Do

* StatsComponent replacement. We use StatsComponent to get min/max of result set, as well as missing count. StatsComponent is included on every non-drilldown request, so ranges and slider can be displayed. However, StatsComponent really can slow down the solr response with a large result set. So replace StatsComponent with other strategies. No ideal ones, we can use facet.missing to get missing count instead, but RSolr makes it harder than it should be to grab this info. We can use seperate solr queries to get min/max (sort on our field, asc and desc), but this is more complicated, more solr queries, and possibly requires redesign of AJAXy stuff, so even a lone slider can have min/max. 
* tests
* In cases where an AJAX request is needed to fetch more results, don't trigger the AJAX until the range facet has actually been opened/shown. Currently it's done on page load. 
* If :assumed_boundaries ends up popular, we could provide a method to fetch min and max values from entire corpus on app startup or in a rake task, and automatically use these as :assumed_boundaries. 

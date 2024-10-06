//import Chart from 'chart.js/auto';

// Selective import to keep package size smaller if we have a bundler that can tree-shake
// https://www.chartjs.org/docs/latest/getting-started/integration.html
import {
  Chart,
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  Filler,
} from "chart.js";

Chart.register(
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  Filler
);


export default class BlacklightRangeLimit {
  static init(args = {}) {
    // args and defaults
    const {
      // a basic vanilla JS onLoad handler as default, but pass in Blacklight.onLoad please
      onLoadHandler = (() => {}),
      callback = (range_limit_obj => {}),
      distributionContainerSelector = ".range_limit .profile .distribution"
    } = args;

    // For turbolinks on_loads, we need to execute this on every page change
    onLoadHandler( () => {
      const range_limit = new BlacklightRangeLimit(document.querySelector(distributionContainerSelector));
      callback(range_limit);
    });
  }

  hideTextFacets = true;

  rangeBuckets = []; // array of objects with bucket range info

  xTicks = []; // array of x values to use as chart ticks

  lineDataPoints = [] // array of objects in Chart.js line chart data format, { x: xVal, y: yVal }

  // <canvas> DOM element
  chartCanvasElement;

  // container should be div.distribution that includes the fetch ranges link, and will
  // be replaced by the chart.
  constructor(container) {
    this.container = container;

    if (!this.container) {
      throw new Error("BlacklightRangeLimit missing argument")
    }

    const bounding = container.getBoundingClientRect();
    if (bounding.width > 0 || bounding.height > 0) {
      this.setup(); // visible, init now
    } else {
      // Delay setup until someone clicks to open the facet, mainly to avoid making
      // extra http request to server if it will never be needed!
      this.whenBecomesVisible(container, target => this.setup());
    }

  }

  // if the range fetch link is still in DOM, fetch ranges from back-end,
  // create chart element in DOM (replacing existing fetch link), chart
  // with chart.js, store state in instance variables.
  //
  // This is idempotent in that if the items it creates appear to already have been
  // created, it will skip creating them.
  setup() {
    // we replace this link in DOM after loaded, so if it's there, we need to load
    const loadLink = this.container.querySelector("a.load_distribution");

    // What we'll do to put the chart on page whether or not we need to load --
    // when query has range limits, we don't need to load, it's already there.
    let handleOnPageData = () => {
      if (this.container.classList.contains("chart_js")) {
        this.extractBucketData();
        this.chartCanvasElement = this.setupDomForChart();
        this.drawChart(this.chartCanvasElement);
      }
    }

    if (loadLink) {
      fetch(loadLink["href"]).
        then( response => response.ok ? response.text() : Promise.reject(response)).
        then( responseBody => new DOMParser().parseFromString(responseBody, "text/html")).
        then( responseDom => responseDom.querySelector(".facet-values")).
        then( element =>  this.container.innerHTML = element.outerHTML  ).
        then( _ => { handleOnPageData()  }).
        catch( error => {
          console.error(error);
        });
    } else {
      handleOnPageData();
    }
  }

  // Extract our bucket ranges from HTML DOM, and store in our instance variables
  extractBucketData(facetListDom = this.container.querySelector(".facet-values")) {
    this.rangeBuckets = Array.from(facetListDom.querySelectorAll("ul.facet-values li")).map( li => {
      let from    = this.parseNum(li.querySelector("span.from")?.getAttribute("data-blrl-begin") || li.querySelector("span.single")?.getAttribute("data-blrl-single"));
      let to      = this.parseNum(li.querySelector("span.to")?.getAttribute("data-blrl-end") || li.querySelector("span.single")?.getAttribute("data-blrl-single"));
      let count   = this.parseNum(li.querySelector("span.facet-count,span.count").innerText);
      let avg     = (count / (to - from + 1));

      return {
        from: from,
        to: to,
        count: count,
        avg: avg,
      }
    });

    this.lineDataPoints = [];
    this.xTicks = [];

    // Points to graph on our line chart to make it look like a histogram.
    // We use the avg as the y-coord, to make the area of each
    // segment proportional to how many documents it holds.
    this.rangeBuckets.forEach(bucket => {
      this.lineDataPoints.push({ x: bucket.from, y: bucket.avg });
      this.lineDataPoints.push({ x: bucket.to + 1, y: bucket.avg });

      this.xTicks.push(bucket.from);
    });

    // remove first and last tick, they are likely to be uneven unhelpful
    if (this.xTicks.length > 4) {
      this.xTicks.shift();
      this.xTicks.pop();
    } else {
      this.xTicks.push(this.xTicks[this.xTicks.length - 1] + 1);
    }

    return undefined;
  }

  setupDomForChart() {
    if(this.chartCanvasElement) {
      // already there, we're good.
      return this.chartCanvasElement;
    }

    let listDiv = this.container.querySelector(".facet-values");

    if (this.hideTextFacets) {
      // We keep the textual facet data as accessible screen-reader, add .sr-only to it though
      listDiv.classList.add("sr-only");
      // and hide the legend as to total range sr-only too
      this.container.closest(".profile").querySelector("p.range").classList.add("sr-only");
    }

    // We create a <chart>, insert it into DOM before listDiv
    this.chartCanvasElement = this.container.ownerDocument.createElement("canvas");
    this.chartCanvasElement.setAttribute("aria-hidden", "true"); // textual facets sr-only are alternative
    this.chartCanvasElement.classList.add("blacklight-range-limit-chart");
    this.container.insertBefore(this.chartCanvasElement, listDiv);

    return this.chartCanvasElement;
  }

  // Draw chart to a <canvas> element
  //
  // Somehow this method should be locally over-rideable if you want to change parameters for chart, just
  // override and draw the chart how you want?
  drawChart(chartCanvasElement) {
    const minX = this.lineDataPoints[0].x;
    const maxX = this.lineDataPoints[this.lineDataPoints.length - 1].x;

    new Chart(chartCanvasElement.getContext("2d"), {
      type: 'line',
      options: {
        // disable all animations
        animation: {
            duration: 0 // general animation time
        },
        hover: {
            animationDuration: 0 // duration of animations when hovering an item
        },
        responsiveAnimationDuration: 0,

        plugins: {
          legend: false,
          tooltip: { enabled: false} // tooltips don't currently show anything useful for our
        },
        elements: {
          // hide points, and hide hover tooltip, which is not useful in our simulated histogram
          point: {
            radius: 0
          }
        },
        scales: {
          x: {
            // scale should go from our actual min and max x values, we need min/max here and in ticks
            min: minX,
            max: maxX,
            type: 'linear',
            afterBuildTicks: axis => {
              // will autoskip to remove ticks that don't fit, but give it our segment boundaries
              // to start with
              axis.ticks = this.xTicks.map(v => ({ value: v }))
            },
            ticks: {
              min: minX,
              max: maxX,
              autoSkip: true, // supposed to skip when can't fit, but does not always work
              maxRotation: 0,
              maxTicksLimit: 4, // try a number that should fit
              callback: (val, index) => {
                // Don't format for locale, these are years, just display as years.
                return val;
                //
              }
            }
          },
          y: {
            beginAtZero: true,
            // hide axis labels and grid lines on y, to save space and
            // because it's kind of meant to be relative?
            ticks: {
              display: false,
            },
            grid: {
              display: false
            }
          }
        },
      },
      data: {
        datasets: [
          {
            data: this.lineDataPoints,
            stepped: true,
            fill: true,
            // hide segments tha just go y 0 to 0 along the bottom
            segment: {
              borderColor: ctx => {
                return (ctx.p0.parsed.y == 0 && ctx.p1.parsed.y == 0) ? 'transparent' : 'rgb(54, 162, 235)';
              },
            },
            // Fill color under line:
            backgroundColor: 'rgba(54, 162, 235, 0.5)'
          }
        ]
      }
    });
  }

  // takes a string and parses into an integer, but throws away commas first, to avoid truncation when there is a comma
  // use in place of javascript's native parseInt
  parseNum(str) {
    return parseInt( String(str).replace(/[^0-9-]/g, ''), 10);
  }

  // https://stackoverflow.com/a/70019478/307106
  whenBecomesVisible(element, callback) {
    const resizeWatcher = new ResizeObserver((entries, observer) => {
      for (const entry of entries) {
         if (entry.contentRect.width !== 0 && entry.contentRect.height !== 0) {
           callback.call(entry.target);
           // turn off observing, we only fire once
           observer.unobserve(entry.target);
         }
       }
    });
    resizeWatcher.observe(element);
  }
}






//window.rangeLimit = BlacklightRangeLimit.init();
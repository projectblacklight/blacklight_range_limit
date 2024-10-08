# our local js
pin_all_from File.expand_path("../app/assets/javascripts/blacklight-range-limit", __dir__), under: "blacklight-range-limit", to: "blacklight-range-limit"


# our dependencies also need to be pinned -- chart.js and it's single dependenchy.
# But instead of including here, we generate into local app, so they can update version
# numbers themselves if they want to, seems preferable.
#
# Chart.js will not work as a vendored pin at present, it has to be pin to "live" CDN.


// takes a string and parses into an integer, but throws away commas first, to avoid truncation when there is a comma
// use in place of javascript's native parseNum
function parseNum(str) {
  str = String(str).replace(/,/g, "");
  return parseInt(str);
}
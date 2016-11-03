"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol ? "symbol" : typeof obj; };

exports.checkSorted = checkSorted;
exports.diffSortedLists = diffSortedLists;
exports.dataframeToD3 = dataframeToD3;
function checkSorted(list) {
  for (var i = 1; i < list.length; i++) {
    if (list[i] <= list[i - 1]) {
      throw new Error("List is not sorted or contains duplicate");
    }
  }
}

function diffSortedLists(a, b) {
  var i_a = 0;
  var i_b = 0;

  a = a || [];
  b = b || [];

  var a_only = [];
  var b_only = [];

  checkSorted(a);
  checkSorted(b);

  while (i_a < a.length && i_b < b.length) {
    if (a[i_a] === b[i_b]) {
      i_a++;
      i_b++;
    } else if (a[i_a] < b[i_b]) {
      a_only.push(a[i_a++]);
    } else {
      b_only.push(b[i_b++]);
    }
  }

  if (i_a < a.length) a_only = a_only.concat(a.slice(i_a));
  if (i_b < b.length) b_only = b_only.concat(b.slice(i_b));
  return {
    removed: a_only,
    added: b_only
  };
}

// Convert from wide: { colA: [1,2,3], colB: [4,5,6], ... }
// to long: [ {colA: 1, colB: 4}, {colA: 2, colB: 5}, ... ]
function dataframeToD3(df) {
  var names = [];
  var length = void 0;
  for (var name in df) {
    if (df.hasOwnProperty(name)) names.push(name);
    if (_typeof(df[name]) !== "object" || typeof df[name].length === "undefined") {
      throw new Error("All fields must be arrays");
    } else if (typeof length !== "undefined" && length !== df[name].length) {
      throw new Error("All fields must be arrays of the same length");
    }
    length = df[name].length;
  }
  var results = [];
  var item = void 0;
  for (var row = 0; row < length; row++) {
    item = {};
    for (var col = 0; col < names.length; col++) {
      item[names[col]] = df[names[col]][row];
    }
    results.push(item);
  }
  return results;
}
//# sourceMappingURL=util.js.map

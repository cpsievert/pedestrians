"use strict";

var _assert = require("assert");

var _assert2 = _interopRequireDefault(_assert);

var _util = require("./util");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

describe("diffSortedLists", function () {
  it("detects basic differences", function () {
    var a = ["a", "b", "c"];
    var b = ["b", "d"];

    var diff = (0, _util.diffSortedLists)(a, b);
    _assert2.default.deepEqual(diff, {
      added: ["d"],
      removed: ["a", "c"]
    });
  });

  it("is case sensitive", function () {
    var a = ["Aa", "aa", "Bb"];
    a.sort();
    var b = ["aa", "bb"];

    var diff = (0, _util.diffSortedLists)(a, b);
    _assert2.default.deepEqual(diff, {
      added: ["bb"],
      removed: ["Aa", "Bb"]
    });
  });

  it("works with numbers", function () {
    var diff = (0, _util.diffSortedLists)([1, 2, 3, 11], [1, 3, 4]);
    _assert2.default.deepEqual(diff, {
      added: [4],
      removed: [2, 11]
    });
  });

  it("handles empty lists", function () {
    var diff = (0, _util.diffSortedLists)([], [1, 2, 3]);
    _assert2.default.deepEqual(diff, { added: [1, 2, 3], removed: [] });

    var diff2 = (0, _util.diffSortedLists)([1, 2, 3], []);
    _assert2.default.deepEqual(diff2, { added: [], removed: [1, 2, 3] });

    var diff3 = (0, _util.diffSortedLists)([1, 2, 3], [1, 2, 3]);
    _assert2.default.deepEqual(diff3, { added: [], removed: [] });

    var diff4 = (0, _util.diffSortedLists)([], []);
    _assert2.default.deepEqual(diff4, { added: [], removed: [] });
  });

  it("checks that arguments are sorted, deduped", function () {
    _assert2.default.throws(function () {
      (0, _util.diffSortedLists)(["a", "a", "b"], []);
    });
    _assert2.default.throws(function () {
      (0, _util.diffSortedLists)(["b", "a"], []);
    });
    _assert2.default.throws(function () {
      (0, _util.diffSortedLists)(["a", "a"], [1, 2]);
    });
    _assert2.default.throws(function () {
      (0, _util.diffSortedLists)([1, 2], ["a", "a"]);
    });
  });
});
//# sourceMappingURL=test-util.js.map

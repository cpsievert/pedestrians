"use strict";

var _assert = require("assert");

var _assert2 = _interopRequireDefault(_assert);

var _filterset = require("./filterset");

var _filterset2 = _interopRequireDefault(_filterset);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

describe("FilterSet", function () {
  var fs = new _filterset2.default();

  // Null .value means no filter is being applied.
  it("defaults to null value", function () {
    _assert2.default.equal(fs.value, null);
  });

  it("handles initial update call", function () {
    fs.update("foo", [3, 5, 7]);
    _assert2.default.deepEqual(fs.value, [3, 5, 7]);
  });

  it("handles mutation via update", function () {
    fs.update("foo", [3, 5, 7, 9]);
    _assert2.default.deepEqual(fs.value, [3, 5, 7, 9]);
  });

  it("uses AND relation between multiple handles", function () {
    fs.update("bar", [5, 7, 9, 11]);
    _assert2.default.deepEqual(fs.value, [5, 7, 9]);

    fs.update("bar", [9, 11, 13]);
    _assert2.default.deepEqual(fs.value, [9]);
  });

  it("empty set is different than no set", function () {
    fs.update("bar", []);
    _assert2.default.deepEqual(fs.value, []);

    fs.clear("bar");
    _assert2.default.deepEqual(fs.value, [3, 5, 7, 9]);
  });

  it("clearing all handles equals null", function () {
    fs.clear("foo");
    _assert2.default.equal(fs.value, null);
  });

  it("can totally reset", function () {
    fs.update("foo", [1, 3, 5]);
    fs.update("bar", [1, 2, 3]);
    _assert2.default.deepEqual(fs.value, [1, 3]);

    fs.reset();
    _assert2.default.equal(fs.value, null);
  });
});
//# sourceMappingURL=test-filterset.js.map

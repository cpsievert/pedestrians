"use strict";

var _assert = require("assert");

var _assert2 = _interopRequireDefault(_assert);

var _index = require("./index");

var _index2 = _interopRequireDefault(_index);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var foo = _index2.default.group("foo");

describe("crosstalk group API", function () {
  it("returns the same object multiple times", function () {
    (0, _assert2.default)(foo === _index2.default.group("foo"));
  });
});

var var1 = foo.var("one");

describe("crosstalk var API", function () {
  it("returns the same object multiple times", function () {
    (0, _assert2.default)(var1 === foo.var("one"));
  });
});
//# sourceMappingURL=test-index.js.map

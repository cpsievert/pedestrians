"use strict";

var _assert = require("assert");

var _assert2 = _interopRequireDefault(_assert);

var _filter = require("./filter");

var filter = _interopRequireWildcard(_filter);

var _group = require("./group");

var _group2 = _interopRequireDefault(_group);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

describe("Filter API", function () {
  var handle1 = filter.createHandle((0, _group2.default)("groupA"));

  it("handles basic read/write cases", function () {
    _assert2.default.deepEqual(handle1.filteredKeys, null);

    handle1.set(["a", "b", "c"]);
    _assert2.default.deepEqual(handle1.filteredKeys, ["a", "b", "c"]);
  });

  var handle2 = filter.createHandle((0, _group2.default)("groupA"));
  it("works with a second handle in the same group", function () {
    (0, _assert2.default)(handle1._filterSet === handle2._filterSet);
    _assert2.default.deepEqual(handle1.filteredKeys, handle2.filteredKeys);
    _assert2.default.deepEqual(handle2.filteredKeys, ["a", "b", "c"]);
  });

  it("isn't impacted by a handle in a different group", function () {
    var otherGroupHandle = filter.createHandle((0, _group2.default)("groupB"));
    otherGroupHandle.set([]);
    _assert2.default.deepEqual(handle1.filteredKeys, handle2.filteredKeys);
    _assert2.default.deepEqual(handle2.filteredKeys, ["a", "b", "c"]);
    otherGroupHandle.clear();
  });

  it("uses the intersection of handle filter values", function () {
    handle2.set(["b", "d"]);
    _assert2.default.deepEqual(handle1.filteredKeys, handle2.filteredKeys);
    _assert2.default.deepEqual(handle2.filteredKeys, ["b"]);
  });

  it("invokes change callbacks", function (done) {
    var callbackCount = 0;

    handle1.on("change", function (e) {
      _assert2.default.deepEqual(e.oldValue, ["b"]);
      _assert2.default.deepEqual(e.value, ["b", "d"]);
      if (++callbackCount === 2) {
        done();
      }
    });
    handle2.on("change", function (e) {
      _assert2.default.deepEqual(e.oldValue, ["b"]);
      _assert2.default.deepEqual(e.value, ["b", "d"]);
      if (++callbackCount === 2) {
        done();
      }
    });

    handle1.set(["a", "b", "c", "d"]);
  });
});
//# sourceMappingURL=test-filter.js.map

"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

exports.createHandle = createHandle;

var _filterset = require("./filterset");

var _filterset2 = _interopRequireDefault(_filterset);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function getFilterSet(group) {
  var fsVar = group.var("filterset");
  var result = fsVar.get();
  if (!result) {
    result = new _filterset2.default();
    fsVar.set(result);
  }
  return result;
}

var id = 1;
function nextId() {
  return id++;
}

function createHandle(group) {
  return new FilterHandle(getFilterSet(group), group.var("filter"));
}

var FilterHandle = function () {
  function FilterHandle(filterSet, filterVar) {
    var handleId = arguments.length <= 2 || arguments[2] === undefined ? "filter" + nextId() : arguments[2];

    _classCallCheck(this, FilterHandle);

    this._filterSet = filterSet;
    this._filterVar = filterVar;
    this._id = handleId;
  }

  _createClass(FilterHandle, [{
    key: "close",
    value: function close() {
      this.clear();
    }
  }, {
    key: "clear",
    value: function clear() {
      this._filterSet.clear(this._id);
      this._onChange();
    }
  }, {
    key: "set",
    value: function set(keys) {
      this._filterSet.update(this._id, keys);
      this._onChange();
    }
  }, {
    key: "on",
    value: function on(eventType, listener) {
      return this._filterVar.on(eventType, listener);
    }
  }, {
    key: "_onChange",
    value: function _onChange() {
      this._filterVar.set(this._filterSet.value);
    }
  }, {
    key: "filteredKeys",
    get: function get() {
      return this._filterSet.value;
    }
  }]);

  return FilterHandle;
}();
//# sourceMappingURL=filter.js.map

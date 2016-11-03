"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _util = require("./util");

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function naturalComparator(a, b) {
  if (a === b) {
    return 0;
  } else if (a < b) {
    return -1;
  } else if (a > b) {
    return 1;
  }
}

var FilterSet = function () {
  function FilterSet() {
    _classCallCheck(this, FilterSet);

    this.reset();
  }

  _createClass(FilterSet, [{
    key: "reset",
    value: function reset() {
      // Key: handle ID, Value: array of selected keys, or null
      this._handles = {};
      // Key: key string, Value: count of handles that include it
      this._keys = {};
      this._value = null;
      this._activeHandles = 0;
    }
  }, {
    key: "update",
    value: function update(handleId, keys) {
      if (keys !== null) {
        keys = keys.slice(0); // clone before sorting
        keys.sort(naturalComparator);
      }

      var _diffSortedLists = (0, _util.diffSortedLists)(this._handles[handleId], keys);

      var added = _diffSortedLists.added;
      var removed = _diffSortedLists.removed;

      this._handles[handleId] = keys;

      for (var i = 0; i < added.length; i++) {
        this._keys[added[i]] = (this._keys[added[i]] || 0) + 1;
      }
      for (var _i = 0; _i < removed.length; _i++) {
        this._keys[removed[_i]]--;
      }

      this._updateValue(keys);
    }

    /**
     * @param {string[]} keys Sorted array of strings that indicate
     * a superset of possible keys.
     */

  }, {
    key: "_updateValue",
    value: function _updateValue() {
      var keys = arguments.length <= 0 || arguments[0] === undefined ? this._allKeys : arguments[0];

      var handleCount = Object.keys(this._handles).length;
      if (handleCount === 0) {
        this._value = null;
      } else {
        this._value = [];
        for (var i = 0; i < keys.length; i++) {
          var count = this._keys[keys[i]];
          if (count === handleCount) {
            this._value.push(keys[i]);
          }
        }
      }
    }
  }, {
    key: "clear",
    value: function clear(handleId) {
      if (typeof this._handles[handleId] === "undefined") {
        return;
      }

      var keys = this._handles[handleId] || [];
      for (var i = 0; i < keys.length; i++) {
        this._keys[keys[i]]--;
      }
      delete this._handles[handleId];

      this._updateValue();
    }
  }, {
    key: "value",
    get: function get() {
      return this._value;
    }
  }, {
    key: "_allKeys",
    get: function get() {
      var allKeys = Object.keys(this._keys);
      allKeys.sort(naturalComparator);
      return allKeys;
    }
  }]);

  return FilterSet;
}();

exports.default = FilterSet;
//# sourceMappingURL=filterset.js.map

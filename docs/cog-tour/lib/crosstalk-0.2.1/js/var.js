"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _typeof = typeof Symbol === "function" && typeof Symbol.iterator === "symbol" ? function (obj) { return typeof obj; } : function (obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol ? "symbol" : typeof obj; };

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _events = require("./events");

var _events2 = _interopRequireDefault(_events);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Var = function () {
  function Var(group, name, /*optional*/value) {
    _classCallCheck(this, Var);

    this._group = group;
    this._name = name;
    this._value = value;
    this._events = new _events2.default();
  }

  _createClass(Var, [{
    key: "get",
    value: function get() {
      return this._value;
    }
  }, {
    key: "set",
    value: function set(value, /*optional*/event) {
      if (this._value === value) {
        // Do nothing; the value hasn't changed
        return;
      }
      var oldValue = this._value;
      this._value = value;
      // Alert JavaScript listeners that the value has changed
      var evt = {};
      if (event && (typeof event === "undefined" ? "undefined" : _typeof(event)) === "object") {
        for (var k in event) {
          if (event.hasOwnProperty(k)) evt[k] = event[k];
        }
      }
      evt.oldValue = oldValue;
      evt.value = value;
      this._events.trigger("change", evt, this);

      // TODO: Make this extensible, to let arbitrary back-ends know that
      // something has changed
      if (global.Shiny && global.Shiny.onInputChange) {
        global.Shiny.onInputChange(".clientValue-" + (this._group.name !== null ? this._group.name + "-" : "") + this._name, value);
      }
    }
  }, {
    key: "on",
    value: function on(eventType, listener) {
      return this._events.on(eventType, listener);
    }
  }, {
    key: "removeChangeListenerfunction",
    value: function removeChangeListenerfunction(eventType, listener) {
      return this._events.off(eventType, listener);
    }
  }]);

  return Var;
}();

exports.default = Var;
//# sourceMappingURL=var.js.map

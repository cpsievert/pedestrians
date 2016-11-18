"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

exports.stamp = stamp;

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var Events = function () {
  function Events() {
    _classCallCheck(this, Events);

    this._types = {};
    this._seq = 0;
  }

  _createClass(Events, [{
    key: "on",
    value: function on(eventType, listener) {
      var subs = this._types[eventType];
      if (!subs) {
        subs = this._types[eventType] = {};
      }
      var sub = "sub" + this._seq++;
      subs[sub] = listener;
      return sub;
    }
  }, {
    key: "off",
    value: function off(eventType, listener) {
      var subs = this._types[eventType];
      if (typeof listener === "function") {
        for (var key in subs) {
          if (subs.hasOwnProperty(key)) {
            if (subs[key] === listener) {
              delete subs[key];
              return;
            }
          }
        }
      } else if (typeof listener === "string") {
        if (subs) {
          delete subs[listener];
          return;
        }
      } else {
        throw new Error("Unexpected type for listener");
      }
    }
  }, {
    key: "trigger",
    value: function trigger(eventType, arg, thisObj) {
      var subs = this._types[eventType];
      for (var key in subs) {
        if (subs.hasOwnProperty(key)) {
          subs[key].call(thisObj, arg);
        }
      }
    }
  }]);

  return Events;
}();

exports.default = Events;


var stampSeq = 1;

function stamp(el) {
  if (el === null) {
    return "";
  }
  if (!el.__crosstalkStamp) {
    el.__crosstalkStamp = "ct" + stampSeq++;
  }
  return el.__crosstalkStamp;
}
//# sourceMappingURL=events.js.map

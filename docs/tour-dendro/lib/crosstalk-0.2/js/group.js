"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

exports.default = group;

var _var2 = require("./var");

var _var3 = _interopRequireDefault(_var2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var groups = {};

function group(groupName) {
  if (!groups.hasOwnProperty(groupName)) {
    groups[groupName] = new Group(groupName);
  }
  return groups[groupName];
}

var Group = function () {
  function Group(name) {
    _classCallCheck(this, Group);

    this.name = name;
    this._vars = {};
  }

  _createClass(Group, [{
    key: "var",
    value: function _var(name) {
      if (typeof name !== "string") {
        throw new Error("Invalid var name");
      }

      if (!this._vars.hasOwnProperty(name)) this._vars[name] = new _var3.default(this, name);
      return this._vars[name];
    }
  }, {
    key: "has",
    value: function has(name) {
      if (typeof name !== "string") {
        throw new Error("Invalid var name");
      }

      return this._vars.hasOwnProperty(name);
    }
  }]);

  return Group;
}();
//# sourceMappingURL=group.js.map

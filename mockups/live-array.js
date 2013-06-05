// Generated by CoffeeScript 1.4.0
var LiveArrayMockup,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

LiveArrayMockup = (function() {

  function LiveArrayMockup(_arg) {
    var container, ignoreIndexZero, _ref;
    container = _arg.container, this.defaultArray = _arg.defaultArray, this.varName = _arg.varName, ignoreIndexZero = _arg.ignoreIndexZero, this.showChanges = _arg.showChanges, this.cssRules = _arg.cssRules, this.showIndices = _arg.showIndices;
    this.$container = container;
    this.$editBox = null;
    this.editIndex = null;
    this.firstIndex = ignoreIndexZero ? 1 : 0;
    if ((_ref = this.showChanges) == null) {
      this.showChanges = ["next"];
    }
    this.$arrayTbl = $("<table>", {
      "class": "array"
    }).append($("<tr>", {
      "class": "array-indices"
    }), $("<tr>", {
      "class": "array-cells"
    }), $("<tr>", {
      "class": "array-annotations"
    }));
    this.$container.append(this.$arrayTbl);
  }

  LiveArrayMockup.prototype.setup = function(stash) {
    var v, _, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results;
    this.theArray = stash[this.varName] = [];
    _ref = this.cssRules;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      _ref1 = _ref[_i], _ = _ref1[0], v = _ref1[1], _ = _ref1[2];
      stash[v] = null;
    }
    _ref2 = this.showIndices;
    _results = [];
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      v = _ref2[_j];
      _results.push(stash[v] = null);
    }
    return _results;
  };

  LiveArrayMockup.prototype.setMode = function(mode) {
    var v, _i, _len, _ref,
      _this = this;
    if (mode === "edit") {
      this.theArray.length = 0;
      if (this.firstIndex === 1) {
        this.theArray.push(null);
      }
      this.$arrayTbl.find("tr").empty();
      if ((this.defaultArray != null) && this.defaultArray.length > this.firstIndex) {
        _ref = this.defaultArray.slice(this.firstIndex);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          v = _ref[_i];
          this.appendCellRaw(v);
        }
      } else {
        this.appendCellRaw(null);
      }
      return this.$arrayTbl.on("click", "tr.array-cells td", {}, function(e) {
        return _this.tdClick(e);
      });
    } else if (mode === "display") {
      this.defaultArray = this.theArray.slice(0);
      return this.$arrayTbl.off("click");
    }
  };

  LiveArrayMockup.prototype.render = function(frame, type) {
    var $col, $selector, className, compare, frameArray, i, index, indexName, indices, showChange, v, _i, _j, _k, _len, _len1, _ref, _ref1, _ref2, _ref3, _ref4, _results;
    frameArray = frame[this.varName];
    this.$arrayTbl.find("td").removeClass();
    while (frameArray.length < this.theArray.length) {
      this.chopLastCell();
    }
    while (frameArray.length > this.theArray.length) {
      this.appendCellRaw(null);
    }
    _ref = this.cssRules;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      _ref1 = _ref[_i], compare = _ref1[0], indexName = _ref1[1], className = _ref1[2];
      index = frame[indexName];
      if (!isNaN(parseInt(index)) && (this.firstIndex <= index && index < frameArray.length)) {
        $col = this.getNthColumn(index);
        $selector = (function() {
          switch (compare) {
            case "<":
              return $col.prevAll();
            case "<=":
              return $col.prevAll().add($col);
            case "=":
              return $col;
            case ">":
              return $col.nextAll();
            case ">=":
              return $col.nextAll().add($col);
          }
        })();
        $selector.addClass(className);
      }
    }
    showChange = __indexOf.call(this.showChanges, type) >= 0;
    for (i in frameArray) {
      v = frameArray[i];
      this.setCellRaw(i, v, showChange);
    }
    indices = {};
    _ref2 = this.showIndices;
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      indexName = _ref2[_j];
      index = frame[indexName];
      if (indices[index] != null) {
        indices[index].push(indexName);
      } else {
        indices[index] = [indexName];
      }
    }
    this.$arrayTbl.find("tr.array-annotations td").empty();
    _results = [];
    for (i = _k = _ref3 = this.firstIndex, _ref4 = frameArray.length; _ref3 <= _ref4 ? _k < _ref4 : _k > _ref4; i = _ref3 <= _ref4 ? ++_k : --_k) {
      if (indices[i] != null) {
        _results.push(this.getNthAnnotation(i).html(indices[i].join(", ")));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  LiveArrayMockup.prototype.txtToRaw = function(txt) {
    if (isNaN(parseInt(txt))) {
      return null;
    } else {
      return parseInt(txt);
    }
  };

  LiveArrayMockup.prototype.rawToTxt = function(txt) {
    return txt;
  };

  LiveArrayMockup.prototype.txtValid = function(txt) {
    return this.txtToRaw(txt) != null;
  };

  LiveArrayMockup.prototype.tdClick = function(event) {
    if ((this.$editBox != null) && event.target === this.$editBox.get(0)) {
      return;
    }
    return this.startEditing($(event.target).index() + this.firstIndex);
  };

  LiveArrayMockup.prototype.startEditing = function(index) {
    var $cell,
      _this = this;
    if (index === this.editIndex) {
      return;
    }
    if ((this.editIndex != null)) {
      this.endEditing(true);
    }
    $cell = this.getNthCell(index);
    this.editIndex = index;
    this.$editBox = $("<input class='inline-input'>");
    this.$editBox.val(this.theArray[index]);
    this.$editBox.width($cell.width());
    this.$editBox.on("blur", function(e) {
      return _this.endEditing(true);
    });
    this.$editBox.on("keydown", function(e) {
      return _this.editKeyDown(e);
    });
    $cell.html(this.$editBox);
    this.getNthColumn(index).addClass("editing");
    this.$editBox.focus();
    return this.$editBox.select();
  };

  LiveArrayMockup.prototype.endEditing = function(save) {
    var $cell, dead, last, txt;
    if (!((this.editIndex != null) && (this.$editBox != null))) {
      return;
    }
    $cell = this.getNthCell(this.editIndex);
    last = this.editIndex === this.theArray.length - 1;
    txt = $cell.children("input").val();
    dead = last && this.editIndex !== this.firstIndex && ((save && !this.txtValid(txt)) || (!save && !(this.theArray[this.editIndex] != null)));
    if (dead) {
      this.chopLastCell();
    } else if (save && this.txtValid(txt)) {
      this.setCellTxt(this.editIndex, txt);
    }
    this.getNthColumn(this.editIndex).removeClass("editing");
    this.editIndex = null;
    return this.$editBox = null;
  };

  LiveArrayMockup.prototype.editKeyDown = function(event) {
    var elt, txt;
    switch (event.keyCode) {
      case 13:
        this.endEditing(true);
        return false;
      case 32:
        this.startEditingNext();
        return false;
      case 9:
        if (event.shiftKey) {
          this.startEditingPrev();
        } else {
          this.startEditingNext();
        }
        return false;
      case 8:
        if (this.$editBox.val() === "") {
          this.startEditingPrev();
          return false;
        }
        break;
      case 37:
        elt = this.$editBox.get(0);
        if (elt.selectionStart === 0 && elt.selectionEnd === 0) {
          this.startEditingPrev();
          return false;
        }
        break;
      case 39:
        txt = this.$editBox.val();
        elt = this.$editBox.get(0);
        if (elt.selectionStart === txt.length && elt.selectionEnd === txt.length) {
          this.startEditingNext();
          return false;
        }
        break;
      case 27:
        this.endEditing(false);
        return false;
    }
  };

  LiveArrayMockup.prototype.getNthCell = function(n) {
    return this.$arrayTbl.find("tr.array-cells").children().eq(n - this.firstIndex);
  };

  LiveArrayMockup.prototype.getNthColumn = function(n) {
    var i;
    i = n - this.firstIndex + 1;
    return this.$arrayTbl.find("tr td:nth-child(" + i + ")");
  };

  LiveArrayMockup.prototype.getNthAnnotation = function(n) {
    var i;
    i = n - this.firstIndex + 1;
    return this.$arrayTbl.find("tr.array-annotations td:nth-child(" + i + ")");
  };

  LiveArrayMockup.prototype.startEditingNext = function() {
    if (this.editIndex === this.theArray.length - 1) {
      if (!this.txtValid(this.$editBox.val())) {
        return;
      }
      this.appendCellRaw(null);
    }
    return this.startEditing(this.editIndex + 1);
  };

  LiveArrayMockup.prototype.startEditingPrev = function() {
    if (this.editIndex > this.firstIndex) {
      return this.startEditing(this.editIndex - 1);
    }
  };

  LiveArrayMockup.prototype.appendCellRaw = function(val, showChanges) {
    var newindex;
    newindex = this.theArray.length;
    this.theArray.push(val);
    this.$arrayTbl.find("tr.array-indices").append("<td>" + newindex + "</td>");
    this.$arrayTbl.find("tr.array-cells").append($("<td>", {
      text: this.rawToTxt(val)
    }));
    this.$arrayTbl.find("tr.array-annotations").append("<td></td>");
    if (showChanges) {
      return this.markChanged(newindex);
    }
  };

  LiveArrayMockup.prototype.chopLastCell = function() {
    this.theArray.length--;
    return this.$arrayTbl.find("td:last-child").remove();
  };

  LiveArrayMockup.prototype.setCellTxt = function(index, txtVal, showChanges) {
    return this.setCellRaw(index, this.txtToRaw(txtVal), showChanges);
  };

  LiveArrayMockup.prototype.setCellRaw = function(index, rawVal, showChanges) {
    var $cell, newhtml, oldhtml;
    this.theArray[index] = rawVal;
    $cell = this.getNthCell(index);
    oldhtml = $cell.html();
    newhtml = this.theArray[index] != null ? "" + this.rawToTxt(this.theArray[index]) : "";
    $cell.html(newhtml);
    if (showChanges && oldhtml !== newhtml) {
      return this.markChanged(index);
    }
  };

  LiveArrayMockup.prototype.markChanged = function(index) {
    var $col;
    $col = this.getNthColumn(index);
    $col.addClass("changed");
    return $col.each(function() {
      return $(this).replaceWith($(this).clone());
    });
  };

  return LiveArrayMockup;

})();

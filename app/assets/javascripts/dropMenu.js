/*
 * DO NOT REMOVE THIS NOTICE
 *
 * PROJECT:   MyGosuMenu
 * VERSION:   1.5.5
 * COPYRIGHT: (c) 2003-2009 Cezary Tomczak
 * LINK:      http://www.gosu.pl/MyGosuMenu/
 * LICENSE:   BSD (revised)
 */

function DropMenu1(id) {

    /* Type of the menu: "horizontal" or "vertical" */
    this.type = "horizontal";

    /* Delay (in miliseconds >= 0): show-hide menu */
    this.delay = {
        "show": 0,
        "hide": 300
    };
    /* Change the default position of sub-menu by Y pixels from top and X pixels from left
     * Negative values are allowed
    this.position = {
        "top": 0,
        "left": 0
    } */
    /* Z-index property for .section */
    this.zIndex = {
        "visible": 1,
        "hidden": -1
    };

    // Browser detection
    this.browser = {
        "ie": Boolean(document.body.currentStyle),
        "ie5": (navigator.appVersion.indexOf("MSIE 5.5") != -1 || navigator.appVersion.indexOf("MSIE 5.0") != -1)
    };
    if (!this.browser.ie) { this.browser.ie5 = false; }

    /* Initialize the menu */
    this.init = function() {
        if (!document.getElementById(this.id)) { return alert("DropMenu1.init() failed. Element '"+ this.id +"' does not exist."); }
        if (this.type != "horizontal" && this.type != "vertical") { return alert("DropMenu1.init() failed. Unknown menu type: '"+this.type+"'"); }
        if (this.browser.ie && this.browser.ie5) { fixWrap(); }
        fixSections();
        parse(document.getElementById(this.id).childNodes, this.tree, this.id);
    };

    /* Search for .section elements and set width for them */
    function fixSections() {
        var arr = document.getElementById(self.id).getElementsByTagName("div");
        var sections = new Array();
        var widths = new Array();

        for (var i = 0; i < arr.length; i++) {
            if (arr[i].className == "section") {
                sections.push(arr[i]);
            }
        }
        for (var i = 0; i < sections.length; i++) {
            widths.push(getMaxWidth(sections[i].childNodes));
        }
        for (var i = 0; i < sections.length; i++) {
            sections[i].style.width = (widths[i]) + "px";
        }
        if (self.browser.ie) {
            for (var i = 0; i < sections.length; i++) {
                setMaxWidth(sections[i].childNodes, widths[i]);
            }
        }
    }

    function fixWrap() {
        var elements = document.getElementById(self.id).getElementsByTagName("a");
        for (var i = 0; i < elements.length; i++) {
            if (/item2/.test(elements[i].className)) {
                elements[i].innerHTML = '<div nowrap="nowrap">'+elements[i].innerHTML+'</div>';
            }
        }
    }

    /* Search for an element with highest width among given nodes, return that width */
    function getMaxWidth(nodes) {
        var maxWidth = 0;
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeType != 1) { continue; }
            if (nodes[i].offsetWidth > maxWidth) { maxWidth = nodes[i].offsetWidth; }
        }
        return maxWidth;
    }

    /* Set width for item2 elements */
    function setMaxWidth(nodes, maxWidth) {
        for (var i = 0; i < nodes.length; i++) {
            if (nodes[i].nodeType == 1 && /item2/.test(nodes[i].className) && nodes[i].currentStyle) {
                if (self.browser.ie5) {
                    nodes[i].style.width = (maxWidth) + "px";
                } else {
                    nodes[i].style.width = (maxWidth - parseInt(nodes[i].currentStyle.paddingLeft) - parseInt(nodes[i].currentStyle.paddingRight)) + "px";
                }
            }
        }
    }

    /* Parse nodes, create events, position elements */
    function parse(nodes, tree, id) {
        for (var i = 0; i < nodes.length; i++) {
            if (1 != nodes[i].nodeType) {
                continue;
            }
            switch (true) {
                // .item1
                case /\bitem1\b/.test(nodes[i].className):
                    nodes[i].id = id + "-" + tree.length;
                    tree.push(new Array());
                    nodes[i].onmouseover = item1over;
                    nodes[i].onmouseout = item1out;
                    break;
                // .item2
                case /\bitem2\b/.test(nodes[i].className):
                    nodes[i].id = id + "-" + tree.length;
                    tree.push(new Array());
                    break;
                // .section
                case /\bsection\b/.test(nodes[i].className):
                    // id, events
                    nodes[i].id = id + "-" + (tree.length - 1) + "-section";
                    nodes[i].onmouseover = sectionOver;
                    nodes[i].onmouseout = sectionOut;
                    // position
                    var box1 = document.getElementById(id + "-" + (tree.length - 1));
                    var box2 = document.getElementById(nodes[i].id);
                    /*if ("horizontal" == self.type) {
                        box2.style.top = box1.offsetTop + box1.offsetHeight + self.position.top + "px";
                        if (self.browser.ie5) {
                            box2.style.left = self.position.left + "px";
                        } else {
                            box2.style.left = box1.offsetLeft + self.position.left + "px";
                        }
                    } else if ("vertical" == self.type) {
                        box2.style.top = box1.offsetTop + self.position.top + "px";
                        if (self.browser.ie5) {
                            box2.style.left = box1.offsetWidth + self.position.left + "px";
                        } else {
                            box2.style.left = box1.offsetLeft + box1.offsetWidth + self.position.left + "px";
                        }
                    } */
                    // sections, sectionsShowCnt, sectionsHideCnt
                    self.sections.push(nodes[i].id);
                    self.sectionsShowCnt.push(0);
                    self.sectionsHideCnt.push(0);
                    break;
            }
            if (nodes[i].childNodes) {
                if (/\bsection\b/.test(nodes[i].className)) {
                    parse(nodes[i].childNodes, tree[tree.length - 1], id + "-" + (tree.length - 1));
                } else {
                    parse(nodes[i].childNodes, tree, id);
                }
            }
        }
    }

    /* event, item1:onmouseover */
    function item1over() {
        var id_section = this.id + "-section";
        if (self.visible) {
            var el = new Element(self.visible);
            el = document.getElementById(el.getParent().id);
            if (/item1-active/.test(el.className)) {
                el.className = el.className.replace(/item1-active/, "item1");
            }
        }
        if (self.sections.contains(id_section)) {
            self.sectionsHideCnt[self.sections.indexOf(id_section)]++;
            var cnt = self.sectionsShowCnt[self.sections.indexOf(id_section)];
            setTimeout(function(a, b) { return function() { self.showSection(a, b); }; } (id_section, cnt), self.delay.show);
        } else {
            if (self.visible) {
                var cnt = self.sectionsHideCnt[self.sections.indexOf(self.visible)];
                setTimeout(function(a, b) { return function() { self.hideSection(a, b); }; } (self.visible, cnt), self.delay.show);
            }
        }
    }

    /* event, item1:onmouseout */
    function item1out() {
        var id_section = this.id + "-section";
        if (self.sections.contains(id_section)) {
            self.sectionsShowCnt[self.sections.indexOf(id_section)]++;
            if (id_section == self.visible) {
                var cnt = self.sectionsHideCnt[self.sections.indexOf(id_section)];
                setTimeout(function(a, b) { return function() { self.hideSection(a, b); }; }(id_section, cnt), self.delay.hide);
            }
        }
    }

    /* event, section:onmouseover */
    function sectionOver() {
        self.sectionsHideCnt[self.sections.indexOf(this.id)]++;
        var el = new Element(this.id);
        el = document.getElementById(el.getParent().id);
        if (!/item1-active/.test(el.className)) {
            el.className = el.className.replace(/item1/, "item1-active");
        }
    }

    /* event, section:onmouseout */
    function sectionOut() {
        self.sectionsShowCnt[self.sections.indexOf(this.id)]++;
        var cnt = self.sectionsHideCnt[self.sections.indexOf(this.id)];
        setTimeout(function(a, b) { return function() { self.hideSection(a, b); }; }(this.id, cnt), self.delay.hide);
    }

    /* Show section (1 argument passed)
     * Try to show section (2 arguments passed) - check cnt with sectionShowCnt */
    this.showSection = function(id, cnt) {
        if (typeof cnt != "undefined") {
            if (cnt != this.sectionsShowCnt[this.sections.indexOf(id)]) { return; }
        }
        this.sectionsShowCnt[this.sections.indexOf(id)]++;
        var el = new Element(id);
        var parent = document.getElementById(el.getParent().id);
        if (!/item1-active/.test(parent.className)) {
            parent.className = parent.className.replace(/item1/, "item1-active");
        }
        if (this.visible) {
            if (id == this.visible) { return; }
            this.hideSection(this.visible);
        }
        //document.getElementById(id).style.display = "block";
        document.getElementById(id).style.visibility = "visible";
        document.getElementById(id).style.zIndex = this.zIndex.visible;
        this.visible = id;
    };

    /* Hide section (1 argument passed)
     * Try to hide section (2 arguments passed) - check cnt with sectionHideCnt */
    this.hideSection = function(id, cnt) {
        if (typeof cnt != "undefined") {
            if (cnt != this.sectionsHideCnt[this.sections.indexOf(id)]) { return; }
        }
        var el = new Element(id);
        var parent = document.getElementById(el.getParent().id);
        parent.className = parent.className.replace(/item1-active/, "item1");
        document.getElementById(id).style.zIndex = this.zIndex.hidden;
        document.getElementById(id).style.visibility = "hidden";
        //document.getElementById(id).style.display = "none";
        if (id == this.visible) { this.visible = ""; }
        else {
            //throw "DropMenu1.hideSection('"+id+"', "+cnt+") failed, cannot hide element that is not visible";
            return;
        }
        this.sectionsHideCnt[this.sections.indexOf(id)]++;
    };

    /* Necessary when showing section that doesn't exist - hide currently visible section. See: item1over() */
    this.hideSelf = function(cnt) {
        if (this.visible && cnt == this.sectionsHideCnt[this.sections.indexOf(this.visible)]) {
            this.hideSection(this.visible);
        }
    };

    /* Element (.section, .item2 etc) */
    function Element(id) {
        /* Get parent element */
        this.getParent = function() {
            var s = this.id.substr(this.menu.id.length);
            var a = s.split("-");
            a.pop();
            return new Element(this.menu.id + a.join("-"));
        };
        this.menu = self;
        this.id = id;
    }

    var self = this;
    this.id = id; /* menu id */
    this.tree = []; /* tree structure of menu */
    this.sections = []; /* all sections, required for timeout */
    this.sectionsShowCnt = [];
    this.sectionsHideCnt = [];
    this.visible = ""; /* visible section, ex. menu-0-section */
}

/* Finds the index of the first occurence of item in the array, or -1 if not found */
if (typeof Array.prototype.indexOf == "undefined") {
    Array.prototype.indexOf = function(item) {
        for (var i = 0; i < this.length; i++) {
            if ((typeof this[i] == typeof item) && (this[i] == item)) {
                return i;
            }
        }
        return -1;
    };
}

/* Check whether array contains given string */
if (typeof Array.prototype.contains == "undefined") {
    Array.prototype.contains = function(s) {
        for (var i = 0; i < this.length; i++) {
            if (this[i] === s) {
                return true;
            }
        }
        return false;
    };
}
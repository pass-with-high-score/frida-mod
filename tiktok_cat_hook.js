/*
 * TikTok - Filter Feed to Cat Content (v11)
 * Based on v9 (which worked). Fix: track already-filtered items,
 * only filter NEW items on load more → no scroll reset.
 * Pure ObjC swizzle. NO Interceptor.
 */

var CAT_KEYWORDS = ["mèo", "cat", "kitten", "kitty", "meow", "neko", "meo", "🐱", "🐈"];

var NSMutableArray = ObjC.classes.NSMutableArray;
var _R = [];
function R(o) { _R.push(o); if (_R.length > 1000) _R.splice(0, 200); return o; }

function matchesCat(text) {
    if (!text) return false;
    var lower = text.toLowerCase();
    for (var i = 0; i < CAT_KEYWORDS.length; i++) {
        if (lower.indexOf(CAT_KEYWORDS[i]) !== -1) return true;
    }
    return false;
}

function getItemText(obj) {
    try {
        if (obj.respondsToSelector_(ObjC.selector("descriptionString"))) {
            var d = obj.descriptionString();
            if (d && !d.isNull()) return d.toString();
        }
    } catch(e) {}
    try {
        if (obj.respondsToSelector_(ObjC.selector("model"))) {
            var m = obj.model();
            if (m && !m.isNull()) return getItemText(m);
        }
    } catch(e) {}
    return "";
}

// Track the last known filtered count per data controller
// so we only filter newly added items
var lastFilteredCount = {};

function filterNewItems(dcObj, label) {
    try {
        var dataSource = dcObj.$ivars["_dataSource"];
        if (!dataSource || dataSource.isNull()) return;

        var arr = new ObjC.Object(dataSource);
        var count = arr.count();
        if (count === 0) return;

        var key = dcObj.handle.toString();
        var prevCount = lastFilteredCount[key] || 0;

        // If data source shrunk (refresh), filter the whole thing
        if (count <= prevCount || prevCount === 0) {
            // Full filter (initial load or pull-to-refresh)
            var toRemove = R(NSMutableArray.alloc().init());
            for (var i = 0; i < count; i++) {
                var item = arr.objectAtIndex_(i);
                var text = getItemText(item);
                if (!matchesCat(text)) {
                    toRemove.addObject_(item);
                }
            }
            if (toRemove.count() > 0 && toRemove.count() < count) {
                arr.removeObjectsInArray_(toRemove);
                var newCount = arr.count();
                console.log("[Cat] " + label + " full filter: " + newCount + " cat items (removed " + toRemove.count() + ")");
                lastFilteredCount[key] = newCount;
            } else {
                lastFilteredCount[key] = count;
            }
            return;
        }

        // Only filter the newly added items (from prevCount to count)
        // Remove non-cat items from the end backwards to keep indices valid
        var removed = 0;
        for (var i = count - 1; i >= prevCount; i--) {
            var item = arr.objectAtIndex_(i);
            var text = getItemText(item);
            if (!matchesCat(text)) {
                arr.removeObjectAtIndex_(i);
                removed++;
            }
        }
        var newCount = arr.count();
        lastFilteredCount[key] = newCount;
        if (removed > 0) {
            console.log("[Cat] " + label + " load more: +" + (newCount - prevCount) + " cat items (filtered " + removed + " non-cat)");
        }
    } catch(e) {
        console.log("[Cat] " + label + " error: " + e.message);
    }
}

// ============================================================
// 1. Hook _onReloadDataSource - filter on every table reload
// ============================================================
try {
    var cls = ObjC.classes.TTKFeedDataService;
    var sel = "- _onReloadDataSource";
    var m = cls[sel];
    var orig = m.implementation;
    var origFn = new NativeFunction(orig, "void", ["pointer", "pointer"]);

    m.implementation = ObjC.implement(m, function(self, _cmd) {
        try {
            var svc = new ObjC.Object(self);
            if (svc.respondsToSelector_(ObjC.selector("dataController"))) {
                var dc = svc.dataController();
                if (dc && !dc.isNull()) {
                    filterNewItems(new ObjC.Object(dc), "reload");
                }
            }
        } catch(e) {}
        origFn(self, _cmd);
    });
    console.log("[+] Hooked _onReloadDataSource");
} catch(e) {
    console.log("[-] _onReloadDataSource: " + e.message);
}

// Pull-to-refresh is handled automatically:
// when data source count shrinks (refresh replaces data),
// the "count <= prevCount" check triggers a full filter.

console.log("\n========================================");
console.log("  TikTok Cat Filter v11");
console.log("  Keywords: " + CAT_KEYWORDS.join(", "));
console.log("  Scroll = filter new items only");
console.log("  Pull refresh = full filter");
console.log("========================================\n");

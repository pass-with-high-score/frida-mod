/*
 * TikTok - Discover networking classes and feed-related methods
 */

console.log("=== Scanning TikTok classes ===\n");

// 1. Find all TTNet / network related classes
var networkKeywords = ["TTNet", "TTHttp", "TTRequest", "BDNet", "BDHttp", "BDRequest", "Cronet", "AWEFeed", "FeedRequest", "FeedService", "FeedAPI", "ItemModel", "AwemeModel", "SearchRequest"];
var foundClasses = {};

ObjC.enumerateLoadedClasses({}, {
    onMatch: function(name) {
        for (var i = 0; i < networkKeywords.length; i++) {
            if (name.indexOf(networkKeywords[i]) !== -1) {
                if (!foundClasses[networkKeywords[i]]) foundClasses[networkKeywords[i]] = [];
                foundClasses[networkKeywords[i]].push(name);
            }
        }
    },
    onComplete: function() {}
});

Object.keys(foundClasses).forEach(function(key) {
    console.log("\n--- " + key + " (" + foundClasses[key].length + " classes) ---");
    foundClasses[key].slice(0, 15).forEach(function(cls) {
        console.log("  " + cls);
    });
    if (foundClasses[key].length > 15) console.log("  ... +" + (foundClasses[key].length - 15) + " more");
});

// 2. Inspect TTNetworkManager methods in detail
console.log("\n\n=== TTNetworkManager methods ===");
try {
    var ttMgr = ObjC.classes.TTNetworkManager;
    if (ttMgr) {
        ttMgr.$ownMethods.forEach(function(m) {
            if (m.indexOf("request") !== -1 || m.indexOf("Request") !== -1 ||
                m.indexOf("send") !== -1 || m.indexOf("Send") !== -1 ||
                m.indexOf("url") !== -1 || m.indexOf("URL") !== -1 ||
                m.indexOf("task") !== -1 || m.indexOf("Task") !== -1) {
                console.log("  " + m);
            }
        });
    }
} catch(e) { console.log("  Error: " + e); }

// 3. Inspect TTNetworkManagerChromium
console.log("\n=== TTNetworkManagerChromium methods ===");
try {
    var ttChrome = ObjC.classes.TTNetworkManagerChromium;
    if (ttChrome) {
        ttChrome.$ownMethods.forEach(function(m) {
            if (m.indexOf("request") !== -1 || m.indexOf("Request") !== -1 ||
                m.indexOf("send") !== -1 || m.indexOf("Send") !== -1 ||
                m.indexOf("url") !== -1 || m.indexOf("URL") !== -1 ||
                m.indexOf("task") !== -1 || m.indexOf("Task") !== -1) {
                console.log("  " + m);
            }
        });
    }
} catch(e) { console.log("  Error: " + e); }

// 4. Look for Feed-related classes and their methods
console.log("\n=== Feed / Aweme classes with key methods ===");
var feedClasses = ["AWEFeedTableViewController", "AWEFeedContainerViewController",
    "AWESearchResultViewController", "AWEFeedService", "AWEFeedManager",
    "AWESearchManager", "AWEFeedRequestManager", "AWEAwemeModel"];

feedClasses.forEach(function(clsName) {
    try {
        var klass = ObjC.classes[clsName];
        if (!klass) return;
        console.log("\n  " + clsName + ":");
        klass.$ownMethods.forEach(function(m) {
            if (m.indexOf("feed") !== -1 || m.indexOf("Feed") !== -1 ||
                m.indexOf("load") !== -1 || m.indexOf("Load") !== -1 ||
                m.indexOf("fetch") !== -1 || m.indexOf("Fetch") !== -1 ||
                m.indexOf("request") !== -1 || m.indexOf("Request") !== -1 ||
                m.indexOf("search") !== -1 || m.indexOf("Search") !== -1 ||
                m.indexOf("refresh") !== -1 || m.indexOf("Refresh") !== -1) {
                console.log("    " + m);
            }
        });
    } catch(e) {}
});

// 5. Scan for protobuf / API route config
console.log("\n=== Looking for API route strings ===");
var mainModule = Process.enumerateModules()[0];
var feedStrings = ["aweme/v1/feed", "aweme/v2/feed", "/feed/", "/recommend/", "item_list"];
feedStrings.forEach(function(s) {
    var results = Memory.scanSync(mainModule.base, mainModule.size, stringToPattern(s));
    console.log("  '" + s + "': " + results.length + " matches");
});

function stringToPattern(str) {
    var hex = [];
    for (var i = 0; i < str.length; i++) {
        hex.push(("0" + str.charCodeAt(i).toString(16)).slice(-2));
    }
    return hex.join(" ");
}

console.log("\n=== Discovery complete ===");

/*
 * TikTok - Discover feed list data source structure
 * Pure ObjC swizzle, NO Interceptor
 */

console.log("=== Discovering Feed List Structure ===\n");

// 1. Find AWEAwemeModel properties (the video item model)
try {
    var cls = ObjC.classes.AWEAwemeModel;
    if (cls) {
        console.log("--- AWEAwemeModel key properties ---");
        cls.$ownMethods.forEach(function(m) {
            if (m.indexOf("desc") !== -1 || m.indexOf("Desc") !== -1 ||
                m.indexOf("title") !== -1 || m.indexOf("Title") !== -1 ||
                m.indexOf("caption") !== -1 || m.indexOf("Caption") !== -1 ||
                m.indexOf("text") !== -1 || m.indexOf("Text") !== -1 ||
                m.indexOf("tag") !== -1 || m.indexOf("Tag") !== -1 ||
                m.indexOf("keyword") !== -1 || m.indexOf("Keyword") !== -1 ||
                m.indexOf("category") !== -1 || m.indexOf("Category") !== -1 ||
                m.indexOf("label") !== -1 || m.indexOf("Label") !== -1 ||
                m.indexOf("author") !== -1 || m.indexOf("Author") !== -1 ||
                m.indexOf("nickname") !== -1 || m.indexOf("Nickname") !== -1) {
                console.log("  " + m);
            }
        });
    }
} catch(e) { console.log("AWEAwemeModel error: " + e.message); }

// 2. Find feed table view controller data source methods
try {
    var feedClasses = [
        "AWEFeedTableViewController",
        "AWEFeedTableView",
        "AWEFeedCellViewController",
    ];
    feedClasses.forEach(function(name) {
        var cls = ObjC.classes[name];
        if (!cls) return;
        console.log("\n--- " + name + " key methods ---");
        cls.$ownMethods.forEach(function(m) {
            if (m.indexOf("dataSource") !== -1 || m.indexOf("DataSource") !== -1 ||
                m.indexOf("numberOfRows") !== -1 || m.indexOf("numberOfItems") !== -1 ||
                m.indexOf("cellForRow") !== -1 || m.indexOf("cellForItem") !== -1 ||
                m.indexOf("aweme") !== -1 || m.indexOf("Aweme") !== -1 ||
                m.indexOf("model") !== -1 || m.indexOf("Model") !== -1 ||
                m.indexOf("items") !== -1 || m.indexOf("Items") !== -1 ||
                m.indexOf("data") !== -1 || m.indexOf("Data") !== -1 ||
                m.indexOf("setData") !== -1 || m.indexOf("setItems") !== -1 ||
                m.indexOf("append") !== -1 || m.indexOf("Append") !== -1 ||
                m.indexOf("insert") !== -1 || m.indexOf("Insert") !== -1 ||
                m.indexOf("reload") !== -1 || m.indexOf("Reload") !== -1 ||
                m.indexOf("refresh") !== -1 || m.indexOf("Refresh") !== -1 ||
                m.indexOf("load") !== -1 || m.indexOf("Load") !== -1 ||
                m.indexOf("fetch") !== -1 || m.indexOf("Fetch") !== -1 ||
                m.indexOf("count") !== -1) {
                console.log("  " + m);
            }
        });
    });
} catch(e) {}

// 3. Find NUJ feed manager (TTKNUJFeedRequestManager)
try {
    var cls = ObjC.classes.TTKNUJFeedRequestManager;
    if (cls) {
        console.log("\n--- TTKNUJFeedRequestManager ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 4. Find AWEFeedPbResponseSerializer (feed response parser)
try {
    var cls = ObjC.classes.AWEFeedPbResponseSerializer;
    if (cls) {
        console.log("\n--- AWEFeedPbResponseSerializer ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 5. Search for classes with "FeedList" or "FeedData"
console.log("\n--- FeedList/FeedData classes ---");
ObjC.enumerateLoadedClasses({}, {
    onMatch: function(name) {
        if (name.indexOf("FeedList") !== -1 || name.indexOf("FeedData") !== -1 ||
            name.indexOf("FeedModel") !== -1 || name.indexOf("FeedItem") !== -1) {
            console.log("  " + name);
        }
    },
    onComplete: function() {}
});

// 6. Find AWEIMFeedListAwemeModel (from discovery)
try {
    var cls = ObjC.classes.AWEIMFeedListAwemeModel;
    if (cls) {
        console.log("\n--- AWEIMFeedListAwemeModel ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

console.log("\n=== Done ===");

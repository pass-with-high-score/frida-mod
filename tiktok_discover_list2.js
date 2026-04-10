/*
 * Discover feed response model + data controller structure
 */

// 1. AWESmartFeedDataController
try {
    var cls = ObjC.classes.AWESmartFeedDataController;
    if (cls) {
        console.log("--- AWESmartFeedDataController ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 2. TTKFeedDataOperator
try {
    var cls = ObjC.classes.TTKFeedDataOperator;
    if (cls) {
        console.log("\n--- TTKFeedDataOperator ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 3. TTKFeedDataService
try {
    var cls = ObjC.classes.TTKFeedDataService;
    if (cls) {
        console.log("\n--- TTKFeedDataService ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 4. FeedItem class
try {
    var cls = ObjC.classes.FeedItem;
    if (cls) {
        console.log("\n--- FeedItem ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 5. GBLFeedItemList
try {
    var cls = ObjC.classes.GBLFeedItemList;
    if (cls) {
        console.log("\n--- GBLFeedItemList ---");
        cls.$ownMethods.forEach(function(m) {
            console.log("  " + m);
        });
    }
} catch(e) {}

// 6. Check live AWESmartFeedDataController instances for their data
try {
    var instances = ObjC.chooseSync(ObjC.classes.AWESmartFeedDataController);
    console.log("\n--- Live AWESmartFeedDataController instances: " + instances.length + " ---");
    if (instances.length > 0) {
        var inst = instances[0];
        // List ivars/properties
        var props = inst.$ivars;
        console.log("  ivars: " + JSON.stringify(Object.keys(props)));
    }
} catch(e) { console.log("chooseSync error: " + e.message); }

// 7. Check AWEAwemeModel live instance
try {
    var models = ObjC.chooseSync(ObjC.classes.AWEAwemeModel);
    console.log("\n--- Live AWEAwemeModel instances: " + models.length + " ---");
    if (models.length > 0) {
        var m = models[0];
        var desc = "";
        try { desc = m.descriptionString().toString(); } catch(e) {}
        var title = "";
        try { title = m.title().toString(); } catch(e) {}
        console.log("  desc: " + desc.substring(0, 100));
        console.log("  title: " + title.substring(0, 100));
    }
} catch(e) { console.log("AWEAwemeModel error: " + e.message); }

console.log("\n=== Done ===");

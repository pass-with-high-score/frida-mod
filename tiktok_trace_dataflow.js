/*
 * Trace the actual data flow path for feed items
 * Pure ObjC swizzle - find which methods are actually called
 */

var NSString = ObjC.classes.NSString;

function safeSwizzleTrace(className, selStr, label) {
    try {
        var cls = ObjC.classes[className];
        if (!cls || !cls[selStr]) return;
        var m = cls[selStr];
        var orig = m.implementation;

        // Count args from selector colons
        var colonCount = (selStr.match(/:/g) || []).length;
        var totalArgs = colonCount + 2; // +self +_cmd
        var argTypes = [];
        for (var i = 0; i < totalArgs; i++) argTypes.push("pointer");

        var origFn = new NativeFunction(orig, "pointer", argTypes);
        m.implementation = ObjC.implement(m, function() {
            console.log("[TRACE] " + label);
            // Forward all arguments
            var a = [];
            for (var i = 0; i < arguments.length; i++) a.push(arguments[i]);
            return origFn.apply(null, a);
        });
        console.log("[+] Tracing " + label);
    } catch(e) {
        console.log("[-] " + label + ": " + e.message);
    }
}

// AWESmartFeedDataController data flow
safeSwizzleTrace("AWESmartFeedDataController", "- handleResponseModel:", "SmartFeed.handleResponseModel");
safeSwizzleTrace("AWESmartFeedDataController", "- handleAfterResponseModel:pullType:", "SmartFeed.handleAfterResponseModel");
safeSwizzleTrace("AWESmartFeedDataController", "- requestCompletion:error:pullType:completion:", "SmartFeed.requestCompletion");
safeSwizzleTrace("AWESmartFeedDataController", "- refreshWithCompletion:", "SmartFeed.refresh");
safeSwizzleTrace("AWESmartFeedDataController", "- loadMoreWithCompletion:", "SmartFeed.loadMore");

// TTKFeedDataService data flow
safeSwizzleTrace("TTKFeedDataService", "- replaceDataSourceWithNewDataSource:param:", "FeedDataService.replaceDataSource");
safeSwizzleTrace("TTKFeedDataService", "- _onReloadDataSource", "FeedDataService._onReloadDataSource");
safeSwizzleTrace("TTKFeedDataService", "- _initialFetch", "FeedDataService._initialFetch");
safeSwizzleTrace("TTKFeedDataService", "- _loadMore", "FeedDataService._loadMore");
safeSwizzleTrace("TTKFeedDataService", "- externalInsertAweme:atIndex:param:", "FeedDataService.externalInsert");

// TTKFeedDataOperator data flow
safeSwizzleTrace("TTKFeedDataOperator", "- updateDataSource:param:", "Operator.updateDataSource");
safeSwizzleTrace("TTKFeedDataOperator", "- addObject:param:", "Operator.addObject");
safeSwizzleTrace("TTKFeedDataOperator", "- insertObject:atIndex:param:", "Operator.insertObject");
safeSwizzleTrace("TTKFeedDataOperator", "- insertAweme:atIndex:checkAndRemove:checkStartPosition:param:", "Operator.insertAweme");

// Response serializer
safeSwizzleTrace("AWEFeedPbResponseSerializer", "- responseObjectForResponse:data:responseError:resultError:", "Serializer.responseObject");
safeSwizzleTrace("AWEFeedPbResponseSerializer", "- responseModelFromPBData:error:response:", "Serializer.fromPBData");
safeSwizzleTrace("AWEFeedPbResponseSerializer", "- responseModelFromJsonData:error:response:", "Serializer.fromJsonData");
safeSwizzleTrace("AWEFeedPbResponseSerializer", "- responseModelFromJson:originType:error:response:", "Serializer.fromJson");

console.log("\n=== Tracing feed data flow ===");
console.log("Pull to refresh / scroll the feed now!\n");

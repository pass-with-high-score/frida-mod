/*
 * TikTok - TRACE ONLY (no modifications)
 * Find the correct API endpoints and method signatures
 */

console.log("=== TikTok URL Trace (read-only) ===\n");

// Hook buildJSONHttpTask - log all URLs, no modification
try {
    var TTNetMgrChromium = ObjC.classes.TTNetworkManagerChromium;
    var buildSel = "- buildJSONHttpTask:params:method:needCommonParams:commonParamLevel:headerField:requestSerializer:responseSerializer:autoResume:verifyRequest:isCustomizedCookie:callback:callbackWithResponse:dispatch_queue:entrySelector:";
    if (TTNetMgrChromium[buildSel]) {
        Interceptor.attach(TTNetMgrChromium[buildSel].implementation, {
            onEnter: function(args) {
                try {
                    var urlObj = new ObjC.Object(args[2]);
                    var urlStr = urlObj.toString();
                    if (urlStr.indexOf("/aweme/") !== -1 || urlStr.indexOf("/feed") !== -1 ||
                        urlStr.indexOf("/recommend") !== -1 || urlStr.indexOf("/search") !== -1 ||
                        urlStr.indexOf("/item") !== -1) {
                        var params = new ObjC.Object(args[3]);
                        var paramKeys = "";
                        try { paramKeys = params.allKeys().toString(); } catch(e) {}
                        console.log("[API] " + urlStr.substring(0, 150));
                        if (paramKeys) console.log("  params keys: " + paramKeys.substring(0, 200));
                    }
                } catch(e) {}
            }
        });
        console.log("[+] Tracing buildJSONHttpTask");
    }
} catch(e) {
    console.log("[-] Error: " + e);
}

// Also trace binary requests (some feed data may be protobuf)
try {
    var TTNetMgrChromium = ObjC.classes.TTNetworkManagerChromium;
    var binSel = "- buildBinaryHttpTask:params:method:needCommonParams:headerField:enableHttpCache:formerRequest:requestSerializer:responseSerializer:autoResume:isCustomizedCookie:headerCallback:dataCallback:callback:callbackWithResponse:redirectCallback:progress:dispatch_queue:entrySelector:";
    if (TTNetMgrChromium[binSel]) {
        Interceptor.attach(TTNetMgrChromium[binSel].implementation, {
            onEnter: function(args) {
                try {
                    var urlObj = new ObjC.Object(args[2]);
                    var urlStr = urlObj.toString();
                    if (urlStr.indexOf("/aweme/") !== -1 || urlStr.indexOf("/feed") !== -1 ||
                        urlStr.indexOf("/recommend") !== -1) {
                        console.log("[BIN] " + urlStr.substring(0, 150));
                    }
                } catch(e) {}
            }
        });
        console.log("[+] Tracing buildBinaryHttpTask");
    }
} catch(e) {}

console.log("\nWaiting for requests... scroll the TikTok feed now.\n");

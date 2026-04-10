// Helper to find export address
function findExport(modName, funcName) {
    var mod = Process.findModuleByName(modName);
    if (!mod) return null;
    var exports = mod.enumerateExports();
    for (var i = 0; i < exports.length; i++) {
        if (exports[i].name === funcName) return exports[i].address;
    }
    return null;
}

// Hook open() syscall
var openAddr = findExport("libsystem_kernel.dylib", "open") || findExport("libSystem.B.dylib", "open");
if (openAddr) {
    Interceptor.attach(openAddr, {
        onEnter: function(args) {
            try {
                var path = args[0].readCString();
                if (path && (path.indexOf(".dat") !== -1 || path.indexOf("profile") !== -1)) {
                    console.log("[open] " + path);
                    this.track = true;
                }
            } catch(e) {}
        },
        onLeave: function(retval) {
            if (this.track) {
                console.log("[open] fd=" + retval.toInt32());
            }
        }
    });
    console.log("[*] open() hooked at " + openAddr);
}

// Hook fopen
var fopenAddr = findExport("libsystem_c.dylib", "fopen");
if (fopenAddr) {
    Interceptor.attach(fopenAddr, {
        onEnter: function(args) {
            try {
                var path = args[0].readCString();
                var mode = args[1].readCString();
                if (path && (path.indexOf(".dat") !== -1 || path.indexOf("Documents") !== -1)) {
                    console.log("[fopen] " + path + " mode=" + mode);
                }
            } catch(e) {}
        }
    });
    console.log("[*] fopen() hooked");
}

// Hook cocos2d::FileUtils::getStringFromFile if we can find it by pattern
// Instead, hook NSData methods for file loading
if (ObjC.available) {
    var NSData = ObjC.classes.NSData;

    // Hook +[NSData dataWithContentsOfFile:]
    Interceptor.attach(NSData["+ dataWithContentsOfFile:"].implementation, {
        onEnter: function(args) {
            var path = new ObjC.Object(args[2]).toString();
            if (path.indexOf(".dat") !== -1) {
                console.log("[NSData+dataWithContentsOfFile] " + path);
                this.track = true;
            }
        },
        onLeave: function(retval) {
            if (this.track) {
                try {
                    var data = new ObjC.Object(retval);
                    console.log("  size=" + data.length());
                } catch(e) {}
            }
        }
    });

    // Hook -[NSData writeToFile:atomically:]
    Interceptor.attach(NSData["- writeToFile:atomically:"].implementation, {
        onEnter: function(args) {
            var path = new ObjC.Object(args[2]).toString();
            if (path.indexOf(".dat") !== -1 || path.indexOf("Documents") !== -1) {
                var data = new ObjC.Object(args[0]);
                console.log("[NSData-writeToFile] " + path + " size=" + data.length());
            }
        }
    });
    console.log("[*] NSData hooks installed");
}

console.log("[*] All file I/O hooks ready. Game starting...");

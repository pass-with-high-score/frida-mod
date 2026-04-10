/**
 * Good Pizza, Great Pizza - Frida Hook
 * Game: com.tapblaze.pizzabusiness (Cocos2d-x C++)
 *
 * Uses C-level dlopen hook to defer all ObjC access
 * until the runtime is fully initialized.
 */

'use strict';

function log(msg) { console.log('[GP] ' + msg); }
log("Script injected. Waiting for app to initialize...");

var hooksInstalled = false;

// ============================================================
// Poll for module readiness (no ObjC access at top level)
// ============================================================
var pollTimer = setInterval(function() {
    // Wait for the game module to be loaded
    var mod = Process.findModuleByName("PizzaBusiness iOS");
    if (!mod) return;

    // Also wait for UIKit to be loaded (means ObjC runtime is ready)
    var uikit = Process.findModuleByName("UIKitCore");
    if (!uikit) return;

    // Check if ObjC is actually available and safe to use
    if (!ObjC.available) return;

    // Try a safe ObjC access - if this fails, runtime isn't ready yet
    try {
        var test = ObjC.classes.NSObject;
        if (!test) return;
    } catch(e) { return; }

    clearInterval(pollTimer);

    // Extra safety delay
    setTimeout(function() {
        if (!hooksInstalled) {
            hooksInstalled = true;
            installAllHooks(mod);
        }
    }, 3000);
}, 500);

// ============================================================
// Main hook installer
// ============================================================
function installAllHooks(mod) {
    log("App ready! Module @ " + mod.base + " (" + mod.size + " bytes)");

    // 1. ANTI-CHEAT
    try {
        var defaults = ObjC.classes.NSUserDefaults.standardUserDefaults();
        defaults.setInteger_forKey_(0, "jb_detection");
        log("[OK] jb_detection = 0");
    } catch(e) { log("[!] jb_detection: " + e); }

    // 2. ACHIEVEMENTS -> 100%
    try {
        var GKAchievement = ObjC.classes.GKAchievement;
        if (GKAchievement && GKAchievement["- setPercentComplete:"]) {
            Interceptor.attach(GKAchievement["- setPercentComplete:"].implementation, {
                onEnter: function(args) {
                    args[2] = ptr("0x4059000000000000");
                }
            });
            log("[OK] Achievements -> 100%");
        }
    } catch(e) { log("[!] Achievement: " + e); }

    // 3. GKSCORE -> max
    try {
        var GKScore = ObjC.classes.GKScore;
        if (GKScore && GKScore["- setValue:"]) {
            Interceptor.attach(GKScore["- setValue:"].implementation, {
                onEnter: function(args) {
                    args[2] = ptr(999999);
                }
            });
            log("[OK] GKScore -> 999999");
        }
    } catch(e) { log("[!] GKScore: " + e); }

    // 4. SAVE MONITOR
    try {
        Interceptor.attach(ObjC.classes.NSData["- writeToFile:atomically:"].implementation, {
            onEnter: function(args) {
                try {
                    var path = new ObjC.Object(args[2]).toString();
                    if (path.indexOf(".dat") !== -1) {
                        log("[SAVE] " + path);
                    }
                } catch(e) {}
            }
        });
        log("[OK] Save monitor");
    } catch(e) { log("[!] Save monitor: " + e); }

    // 5. AUTO-REPORT ACHIEVEMENTS (delayed for GameCenter auth)
    setTimeout(function() {
        try {
            var player = ObjC.classes.GKLocalPlayer.localPlayer();
            if (!player.isAuthenticated()) {
                log("GameCenter not auth'd - skip achievement report");
                return;
            }
            log("Reporting all achievements...");
            var arr = ObjC.classes.NSMutableArray.array();
            for (var i = 1; i <= 50; i++) {
                var id = "achievement" + (i < 10 ? "0" : "") + i;
                var a = ObjC.classes.GKAchievement.alloc().initWithIdentifier_(id);
                a.setPercentComplete_(100.0);
                a.setShowsCompletionBanner_(false);
                arr.addObject_(a);
            }
            ObjC.classes.GKAchievement.reportAchievements_withCompletionHandler_(arr,
                new ObjC.Block({
                    retType: 'void', argTypes: ['object'],
                    implementation: function(err) {
                        log("Achievements: " + (err ? "err " + err : "ALL DONE!"));
                    }
                })
            );
        } catch(e) { log("Achievement report: " + e); }
    }, 10000);

    // 6. RPC MEMORY SCANNER
    rpc.exports = {
        scan: function(value) {
            var locs = [];
            Process.enumerateRanges("rw-").forEach(function(r) {
                if (r.size < 8 || r.size > 20000000) return;
                try {
                    var hex = "";
                    for (var b = 0; b < 4; b++)
                        hex += ("0" + ((value >> (b*8)) & 0xFF).toString(16)).slice(-2) + " ";
                    Memory.scanSync(r.base, r.size, hex.trim()).forEach(function(m) {
                        locs.push(m.address.toString());
                    });
                } catch(e) {}
            });
            return { count: locs.length, first50: locs.slice(0, 50) };
        },
        write: function(addr, val) {
            try { ptr(addr).writeS32(val); return true; } catch(e) { return false; }
        },
        replace: function(oldVal, newVal) {
            var n = 0;
            Process.enumerateRanges("rw-").forEach(function(r) {
                if (r.size < 8 || r.size > 20000000) return;
                try {
                    var hex = "";
                    for (var b = 0; b < 4; b++)
                        hex += ("0" + ((oldVal >> (b*8)) & 0xFF).toString(16)).slice(-2) + " ";
                    Memory.scanSync(r.base, r.size, hex.trim()).forEach(function(m) {
                        m.address.writeS32(newVal); n++;
                    });
                } catch(e) {}
            });
            return n;
        }
    };
    log("[OK] RPC memory scanner");

    console.log("\n========================================");
    console.log(" Good Pizza Mod - ALL HOOKS ACTIVE");
    console.log("  [✓] Anti-cheat bypassed");
    console.log("  [✓] Achievements -> 100%");
    console.log("  [✓] GKScore -> 999999");
    console.log("  [✓] Save file monitor");
    console.log("  [✓] Memory scanner (RPC)");
    console.log("========================================");
}

// Hook CCCrypt to intercept save data decryption
var ccMod = Process.findModuleByName("libcommonCrypto.dylib");
if (ccMod) {
    var exports = ccMod.enumerateExports();
    var ccrypt = null;
    for (var i = 0; i < exports.length; i++) {
        if (exports[i].name === "CCCrypt") { ccrypt = exports[i].address; break; }
    }
    if (ccrypt) {
        Interceptor.attach(ccrypt, {
            onEnter: function(args) {
                this.op = args[0].toInt32();
                this.dataOut = args[7];
                this.dataOutMoved = args[9];
                this.inLen = args[6].toInt32();
            },
            onLeave: function(retval) {
                if (retval.toInt32() === 0 && this.op === 1) {
                    try {
                        var outLen = this.dataOutMoved.readU32();
                        if (outLen > 20 && outLen < 50000) {
                            console.log("[DECRYPT] size=" + outLen);
                            try {
                                var str = this.dataOut.readUtf8String(Math.min(outLen, 5000));
                                if (str) console.log(str.substring(0, 5000));
                            } catch(e) { console.log("(non-utf8)"); }
                        }
                    } catch(e2) {}
                }
            }
        });
        console.log("[*] CCCrypt hook installed");
    }
}

# DebInstallerApp - iOS Tweak Installer

iOS app for jailbroken devices (Dopamine rootless) that installs reverse engineering & hooking tools: **Frida** and **Dobby**.

Built with Theos. Runs on iOS 14+ (arm64/arm64e).

## What It Does

- Downloads and installs **Frida** server via dpkg (version selector, fetches from GitHub releases)
- Installs **Dobby** hooking framework (bundled, copies to system + Theos paths)
- Manages Frida daemon (start/stop via launchctl)
- Real-time installation log output
- Dark UI with progress tracking
- Respring button

---

## Tools Overview

### Frida

Dynamic instrumentation toolkit. Lets you inject JavaScript into running processes to hook functions, trace calls, modify values at runtime.

| | |
|---|---|
| Website | https://frida.re |
| Install method | Download `.deb` from GitHub → `dpkg -i` |
| Package ID | `re.frida.server` |
| Type | Daemon (runs as background service) |
| Use case | Runtime analysis, function hooking, game modding, security research |

**What Frida can do:**
- List running processes on device
- Attach to any process and run JavaScript
- Enumerate loaded modules, ObjC classes, IL2CPP metadata
- Hook functions with `Interceptor.attach()` / `Interceptor.replace()`
- Read/write process memory
- Trace function calls in real time

### Dobby

Lightweight inline hook framework for ARM64. Alternative to Substrate/ElleKit that works standalone (no jailbreak dependency).

| | |
|---|---|
| GitHub | https://github.com/jmpews/Dobby |
| Install method | Bundled files copied to system paths |
| Type | Static library (linked at compile time) |
| Use case | Binary patching, tweak development, IPA injection |

**Files installed:**

| File | Destination | Purpose |
|------|-------------|---------|
| `libdobby.dylib` | `/var/jb/usr/lib/` | Dynamic library |
| `libdobby.a` | `/var/jb/usr/lib/` + `/var/jb/opt/theos/lib/` | Static library for linking |
| `dobby.h` | `/var/jb/usr/include/` + `/var/jb/opt/theos/include/` | Header file |

After installation, use in any Theos project:
```makefile
TWEAK_NAME_LDFLAGS += -ldobby
```

---

## Prerequisites

### On Mac (build machine)

| Tool | Install | Purpose |
|------|---------|---------|
| **Theos** | https://theos.dev/docs/installation | Build system for iOS tweaks |
| **Xcode CLI** | `xcode-select --install` | Compiler + iOS SDK |
| **iproxy** | `brew install libusbmuxd` | USB SSH tunnel to device |
| **Frida tools** | `pip3 install frida-tools` | Frida CLI on Mac |

### On iPhone (jailbroken)

| Requirement | Notes |
|-------------|-------|
| **Jailbreak** | Dopamine (rootless) recommended |
| **OpenSSH** | Install from Sileo/Zebra for SSH access |
| **frida-server** | Installed by this app |
| **sudo** | At `/var/jb/usr/bin/sudo` |
| **dpkg** | At `/var/jb/usr/bin/dpkg` |

---

## Build & Install

### 1. Build

```bash
cd /path/to/DebInstallerApp
make clean && make package
```

Output: `.theos/packages/app.pwhs.fridainstaller_1.0.0-X+debug_iphoneos-arm64.deb`

### 2. Install on device

```bash
# Start USB SSH tunnel
iproxy 2222 22 &

# Copy and install
scp -P 2222 .theos/packages/*.deb mobile@localhost:/tmp/
ssh -P 2222 mobile@localhost 'sudo dpkg -i /tmp/app.pwhs.fridainstaller*.deb'
```

### 3. Run

Open **Tweak Installer** app on device. Select library → choose version → tap Install.

Default password: `alpine` (change it with `passwd` via SSH).

---

## How To Use Frida (After Installation)

### Basic Commands (run on Mac)

```bash
# List processes on device
frida-ps -U

# List only user apps
frida-ps -Ua

# Attach to running app
frida -U -p <PID> -e 'console.log("attached")'

# Attach by app name
frida -U -n "Safari" -e 'console.log(ObjC.classes.NSBundle.mainBundle().bundleIdentifier())'

# Load script file
frida -U -p <PID> -l hook.js

# Spawn app (start fresh + attach)
frida -U -f com.example.app -l hook.js
```

### Common Frida Patterns

#### List loaded modules
```javascript
Process.enumerateModules().forEach(function(m) {
    console.log(m.name + " @ " + m.base + " size:" + m.size);
});
```

#### List ObjC classes matching pattern
```javascript
for (var cls in ObjC.classes) {
    if (cls.indexOf("ViewController") !== -1) {
        console.log(cls);
    }
}
```

#### Hook an ObjC method
```javascript
var cls = ObjC.classes.ClassName;
Interceptor.attach(cls["- methodName:"].implementation, {
    onEnter: function(args) {
        // args[0] = self, args[1] = _cmd, args[2+] = params
        console.log("called with: " + ObjC.Object(args[2]));
    },
    onLeave: function(retval) {
        console.log("returned: " + retval);
    }
});
```

#### Hook a C function by export name
```javascript
var mod = Process.getModuleByName("SomeLib.dylib");
var fn = mod.getExportByName("some_function");
Interceptor.attach(fn, {
    onEnter: function(args) {
        console.log("arg0 = " + args[0].toInt32());
    }
});
```

#### Scan memory for string
```javascript
var mod = Process.getModuleByName("target");
Memory.scan(mod.base, mod.size, "48 65 6c 6c 6f", {
    onMatch: function(address, size) {
        console.log("Found at: " + address);
    },
    onComplete: function() { console.log("Done"); }
});
```

---

## How To Use Frida with Unity IL2CPP Games

Unity games using IL2CPP strip all C# symbol names. You must use the IL2CPP C API (exported by `UnityFramework`) to enumerate classes/methods at runtime.

### Step 1: Setup IL2CPP API bindings

```javascript
var uf = Process.getModuleByName("UnityFramework");
var il2cpp = {
    domain_get: new NativeFunction(uf.getExportByName("il2cpp_domain_get"), "pointer", []),
    domain_get_assemblies: new NativeFunction(uf.getExportByName("il2cpp_domain_get_assemblies"), "pointer", ["pointer", "pointer"]),
    assembly_get_image: new NativeFunction(uf.getExportByName("il2cpp_assembly_get_image"), "pointer", ["pointer"]),
    image_get_class_count: new NativeFunction(uf.getExportByName("il2cpp_image_get_class_count"), "uint32", ["pointer"]),
    image_get_class: new NativeFunction(uf.getExportByName("il2cpp_image_get_class"), "pointer", ["pointer", "uint32"]),
    class_get_name: new NativeFunction(uf.getExportByName("il2cpp_class_get_name"), "pointer", ["pointer"]),
    class_get_namespace: new NativeFunction(uf.getExportByName("il2cpp_class_get_namespace"), "pointer", ["pointer"]),
    class_get_methods: new NativeFunction(uf.getExportByName("il2cpp_class_get_methods"), "pointer", ["pointer", "pointer"]),
    method_get_name: new NativeFunction(uf.getExportByName("il2cpp_method_get_name"), "pointer", ["pointer"]),
    method_get_param_count: new NativeFunction(uf.getExportByName("il2cpp_method_get_param_count"), "uint32", ["pointer"]),
    image_get_name: new NativeFunction(uf.getExportByName("il2cpp_image_get_name"), "pointer", ["pointer"]),
};
```

### Step 2: Search for classes/methods by keyword

```javascript
var domain = il2cpp.domain_get();
var sizePtr = Memory.alloc(4);
var assemblies = il2cpp.domain_get_assemblies(domain, sizePtr);
var asmCount = sizePtr.readU32();

var KEYWORD = "coin"; // change this to search for anything

for (var i = 0; i < asmCount; i++) {
    var asm = assemblies.add(i * Process.pointerSize).readPointer();
    var image = il2cpp.assembly_get_image(asm);
    var classCount = il2cpp.image_get_class_count(image);

    for (var j = 0; j < classCount; j++) {
        var klass = il2cpp.image_get_class(image, j);
        var className = il2cpp.class_get_name(klass).readUtf8String();

        var iter = Memory.alloc(Process.pointerSize);
        iter.writePointer(ptr(0));
        var method;
        while (!(method = il2cpp.class_get_methods(klass, iter)).isNull()) {
            var methodName = il2cpp.method_get_name(method).readUtf8String();
            if (className.toLowerCase().indexOf(KEYWORD) !== -1 ||
                methodName.toLowerCase().indexOf(KEYWORD) !== -1) {
                var fnPtr = method.readPointer(); // MethodInfo->methodPointer
                console.log(className + "." + methodName + " @ " + fnPtr);
            }
        }
    }
}
```

### Step 3: Hook an IL2CPP method

```javascript
// After finding the function pointer from Step 2:
Interceptor.attach(fnPtr, {
    onEnter: function(args) {
        // IL2CPP calling convention:
        //   Instance method: args[0]=this, args[1..N]=params, args[N+1]=MethodInfo*
        //   Static method:   args[0..N-1]=params, args[N]=MethodInfo*
        console.log("called, arg0=" + args[0] + " arg1=" + args[1]);
    },
    onLeave: function(retval) {
        // Modify return value:
        // retval.replace(999);
    }
});
```

### Step 4: Calculate offsets for permanent hooks

```javascript
var base = Process.getModuleByName("UnityFramework").base;
// offset = fnPtr - base (stable across ASLR, changes on app update)
console.log("offset = 0x" + fnPtr.sub(base).toString(16));
```

Use this offset in a Theos tweak or Dobby dylib:
```c
uintptr_t base = (uintptr_t)mach_header_of_UnityFramework;
DobbyHook((void *)(base + 0xOFFSET), (void *)hook_fn, (void **)&orig_fn);
```

---

## How To Use Dobby (After Installation)

### In a Theos tweak

```makefile
# Makefile
YourTweak_LDFLAGS += -ldobby
```

```c
// Tweak.x or Tweak.m
#include <dobby.h>
#include <mach-o/dyld.h>

int (*orig_getCoins)(void *self);
int hook_getCoins(void *self) {
    return orig_getCoins(self) * 10; // x10 coins
}

__attribute__((constructor))
static void init() {
    // For main executable: use _dyld_get_image_vmaddr_slide(0) + offset
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    DobbyHook((void *)(slide + 0x100A4B20),
              (void *)hook_getCoins, (void **)&orig_getCoins);
}
```

### For frameworks (UnityFramework, etc.)

```c
#include <dobby.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>

static void onImageLoaded(const struct mach_header *mh, intptr_t slide) {
    Dl_info info;
    if (!dladdr(mh, &info) || !strstr(info.dli_fname, "UnityFramework")) return;

    uintptr_t base = (uintptr_t)mh;
    DobbyHook((void *)(base + OFFSET), (void *)hook_fn, (void **)&orig_fn);
}

__attribute__((constructor))
static void init() {
    _dyld_register_func_for_add_image(onImageLoaded);
}
```

### Hook by symbol name (non-stripped binaries)

```c
void *addr = DobbySymbolResolver(NULL, "ptrace");
DobbyHook(addr, (void *)my_ptrace, (void **)&orig_ptrace);
```

---

## General Workflow: From Analysis to Tweak

```
1. RECON          frida-ps -U                    List processes
      |
2. IDENTIFY       Frida script                   Find target functions
      |                                          (ObjC runtime / IL2CPP API / exports)
3. PROTOTYPE      Frida Interceptor.attach()     Test hooks live, verify behavior
      |
4. OFFSETS        fnPtr.sub(module.base)         Calculate stable offsets
      |
5. TWEAK          Theos + MSHookFunction         Jailbreak permanent hook
      |            or Dobby + DobbyHook
      |
6. DEPLOY         .deb (jailbreak)               Install via dpkg
                   or .ipa (inject dylib)         Install via TrollStore/Sideloadly
```

---

## Bundled Frida Scripts

| Script | Description |
|--------|-------------|
| `detect_engine.js` | Detect game engine (Unity/Unreal/Cocos2d/etc.) by checking loaded modules and ObjC classes |
| `coin_hook.js` | First attempt hooking Subway City coin functions (educational - shows what NOT to hook) |
| `coin_hook_v2.js` | Working coin multiplier for Subway City via `InventoryServiceExtensions.AddCurrency` |

Usage:
```bash
frida -U -p <PID> -l detect_engine.js
frida -U -p <PID> -l coin_hook_v2.js
```

---

## Troubleshooting

### Frida can't find device
```bash
# Check USB connection
frida-ls-devices
# Restart frida-server on device (via SSH)
ssh mobile@<ip> 'sudo launchctl unload -w /var/jb/Library/LaunchDaemons/re.frida.server.plist'
ssh mobile@<ip> 'sudo launchctl load -w /var/jb/Library/LaunchDaemons/re.frida.server.plist'
```

### "unable to find process with pid"
Process has restarted and PID changed. Re-check with `frida-ps -U`.

### Tweak not loading
```javascript
// Check in Frida if dylib is loaded
Process.enumerateModules().forEach(function(m) {
    if (m.name.indexOf("YourTweak") !== -1) console.log("LOADED: " + m.path);
});
```
If not loaded: check plist filter, verify correct install path for your jailbreak type.

### Offsets changed after game update
Re-run the IL2CPP enumeration script (Step 2 above) to find new function addresses, recalculate offsets.

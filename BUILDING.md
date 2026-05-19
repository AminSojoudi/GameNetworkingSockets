Building
---

## Dependencies

* CMake 3.9 or later (see `cmake_minimum_required` in the root `CMakeLists.txt`)
* A build tool like Ninja, GNU Make or Visual Studio
* A C++11-compliant compiler, such as:
  * GCC 7.3 or later
  * Clang 3.3 or later
  * Visual Studio 2017 or later
* One of the following crypto solutions:
  * OpenSSL 1.1.1 or later
  * libsodium (can cause issues on Intel machines with AES-NI disabled see [here](https://github.com/ValveSoftware/GameNetworkingSockets/issues/243))
  * [bcrypt](https://docs.microsoft.com/en-us/windows/desktop/api/bcrypt/)
    (Windows only.  Note the primary reason this is supported is to satisfy
    an Xbox requirement.)
* Google protobuf 2.6.1+
* Google [webrtc](https://opensource.google/projects/webrtc) is used for
  NAT piercing (ICE) for P2P connections.  The relevant code is linked in as a
  git submodule.  Initialize that submodule only if you enable P2P / WebRTC
  (`-DUSE_STEAMWEBRTC=ON`).  Default / vcpkg manifest builds do not require it.

## Known Issues
* The build may have link errors when building with LLVM 10+:
  [LLVM bug #46313](https://bugs.llvm.org/show_bug.cgi?id=46313). As
  a workaround, consider building the library with GCC instead.

## Linux

### OpenSSL and protobuf

Just use the appropriate package manager.

Ubuntu/debian:

```
# apt install libssl-dev
# apt install libprotobuf-dev protobuf-compiler
```

Arch Linux:

```
# pacman -S openssl
# pacman -S protobuf
```

### Building

Using CMake (preferred):

```
$ mkdir build
$ cd build
$ cmake -G Ninja ..
$ ninja
```

## Using vcpkg to install the gamenetworkingsockets package

If you are using [vcpkg](https://github.com/microsoft/vcpkg/) and are OK with the latest release and default configuration (OpenSSL for the crypto backend, P2P disabled), then you do not need to sync any of this code or build gamenetworkingsockets explicitly.  You can install it directly from the vcpkg registry:

```
vcpkg install gamenetworkingsockets
```

Then include the headers in your project as, e.g.:

```cpp
#include <steam/steamnetworkingsockets.h>
```

See [this example](examples/vcpkg_example_chat/README.md) for more.

## Release-style builds: `scripts/ci/` (local and GitHub Actions)

The repository includes bash scripts (and one PowerShell script for Windows) that
bootstrap a pinned [vcpkg](https://github.com/microsoft/vcpkg) commit, configure
CMake in **Release** mode with tests/examples/tools **off**, and install into a
prefix. These are what **`.github/workflows/release.yml`**, **`android.yml`**, and
**`ios.yml`** invoke, so you can reproduce CI and release packaging locally.

### Environment variables (all scripts)

| Variable | Default | Meaning |
|----------|---------|---------|
| `VCPKG_ROOT` | `<repo>/vcpkg` | vcpkg clone location |
| `VCPKG_COMMIT` | Pin in `scripts/ci/common.sh` | Exact vcpkg git commit (match workflows if you want identical deps) |
| `BUILD_DIR` | Per-script path under the repo | CMake build directory |
| `INSTALL_PREFIX` | Per-script path under the repo | `cmake --install` destination |
| `PACKAGE_NAME` | *(unset)* | If set, creates an archive in the **current working directory** after install (see below) |

### Scripts

| Script | Host OS | Target |
|--------|---------|--------|
| [`scripts/ci/bootstrap-vcpkg.sh`](scripts/ci/bootstrap-vcpkg.sh) | Linux, macOS | Clone/checkout and bootstrap vcpkg only |
| [`scripts/ci/ci-build-linux-x64.sh`](scripts/ci/ci-build-linux-x64.sh) | Linux | `x64-linux` |
| [`scripts/ci/ci-build-macos-arm64.sh`](scripts/ci/ci-build-macos-arm64.sh) | macOS (Apple Silicon typical) | `arm64-osx` |
| [`scripts/ci/ci-build-android.sh`](scripts/ci/ci-build-android.sh) | Linux, macOS | Android (see below) |
| [`scripts/ci/ci-build-ios.sh`](scripts/ci/ci-build-ios.sh) | macOS + Xcode | iOS device or simulator (see below) |
| [`scripts/ci/ci-build-windows-x64.ps1`](scripts/ci/ci-build-windows-x64.ps1) | Windows | `x64-windows`, OpenSSL, MSVC + Ninja |
| [`scripts/ci/package-install-tree.sh`](scripts/ci/package-install-tree.sh) | Any | Pack an existing install prefix (`--prefix`, `--name`, `--format tgz\|zip`) |
| [`scripts/ci/flatten-release-assets.sh`](scripts/ci/flatten-release-assets.sh) | Any | Used by the release workflow to collect artifacts |

**Linux** (example — install Ninja and a compiler toolchain first, e.g. `ninja-build`, `pkg-config`, `build-essential` on Debian/Ubuntu):

```bash
cd /path/to/GameNetworkingSockets
bash scripts/ci/ci-build-linux-x64.sh
# Optional tarball in the current directory:
PACKAGE_NAME=GameNetworkingSockets-local-linux-x64 bash scripts/ci/ci-build-linux-x64.sh
```

**macOS (desktop library)** — Xcode Command Line Tools and Ninja:

```bash
cd /path/to/GameNetworkingSockets
bash scripts/ci/ci-build-macos-arm64.sh
```

**Windows** — run from **x64 Native Tools Command Prompt for VS**, **Developer PowerShell for VS**, or any shell after MSVC env vars are set (as on GitHub Actions):

```powershell
cd C:\path\to\GameNetworkingSockets
$env:PACKAGE_NAME = "GameNetworkingSockets-local-windows-x64"   # optional
pwsh scripts/ci/ci-build-windows-x64.ps1
```

### Android (vcpkg + NDK)

Prerequisites: [Android NDK](https://developer.android.com/ndk) (the directory
must contain `build/cmake/android.toolchain.cmake`), CMake, Ninja, `pkg-config`.

```bash
export ANDROID_NDK_HOME=/path/to/ndk
cd /path/to/GameNetworkingSockets
bash scripts/ci/ci-build-android.sh --triplet arm64-android --abi arm64-v8a
# armeabi-v7a:
# bash scripts/ci/ci-build-android.sh --triplet arm-neon-android --abi armeabi-v7a
```

`--no-install` configures and builds only (used by **`.github/workflows/android.yml`**
to upload `libGameNetworkingSockets.so` from the build tree).

The script sets `-DANDROID_PLATFORM=android-24` and `-DCMAKE_HAVE_LIBC_PTHREAD=ON`
for typical NDK + vcpkg setups.

### iOS (vcpkg, static library)

Must run on **macOS** with **Xcode**. CMake, Ninja, and vcpkg (via the scripts)
supply dependencies. The script forces **static** GNS (`BUILD_SHARED_LIB=OFF`,
`BUILD_STATIC_LIB=ON`), which matches common Xcode / vcpkg iOS usage.

```bash
cd /path/to/GameNetworkingSockets
bash scripts/ci/ci-build-ios.sh --triplet arm64-ios
# Apple Silicon simulator:
# bash scripts/ci/ci-build-ios.sh --triplet arm64-ios-simulator
# Intel simulator (when building from an Intel Mac or cross-compiling):
# bash scripts/ci/ci-build-ios.sh --triplet x64-ios
```

Optional: `IOS_DEPLOYMENT_TARGET` or `--deployment-target` (default `13.0`).

### GitHub Actions

* **[`.github/workflows/android.yml`](.github/workflows/android.yml)** — Android matrix (arm64 / armeabi-v7a), build-only artifacts.
* **[`.github/workflows/ios.yml`](.github/workflows/ios.yml)** — iOS device + simulator triplets; uploads the install tree per triplet.
* **[`.github/workflows/release.yml`](.github/workflows/release.yml)** — On `git push` of a tag `v*`, builds packaged install trees for Linux, Windows, macOS, Android, and iOS, then creates a **GitHub Release** with those archives. **Manual `workflow_dispatch`** runs the same build jobs without publishing a release (unless the ref is a version tag).

Tagged release file names look like `GameNetworkingSockets-<tag>-<platform>.tar.gz` (`.zip` on Windows). Archives contain headers, libraries, and the CMake package from `cmake --install`; they do **not** vendor Protobuf/OpenSSL — link those the same way you would when using vcpkg in your project.

### Updating the vcpkg pin

Change `VCPKG_COMMIT` in **`scripts/ci/common.sh`** and the `VCPKG_COMMIT` env in
**`.github/workflows/android.yml`**, **`ios.yml`**, and **`release.yml`** together
so local builds and Actions stay aligned.

### CI scripts vs `.gitignore` (`**/build-*`)

The repo’s **`.gitignore`** includes **`**/build-*`** so local CMake output trees
like `build-android-arm64` stay untracked. That pattern would also match script
names such as `build-android.sh`, so the drivers are named **`ci-build-*.sh`**
and **`ci-build-windows-x64.ps1`** instead.

If **`bash: …/scripts/ci/ci-build-*.sh: No such file or directory`** appears in
Actions, the clone does not contain those files — commit and push them:

```bash
git add scripts/ci/ci-build-*.sh scripts/ci/ci-build-windows-x64.ps1
git status
git commit -m "Add CI build scripts"
git push
```

Also ensure **`.gitattributes`** keeps `*.sh` as **LF** (`git add --renormalize scripts/ci` on Windows if needed).

## Windows / Visual Studio

To build gamenetworkingsockets on Windows, it's recommended to obtain the dependencies by using vcpkg in ["manifest mode"](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode).  The following instructions assume that you will follow the vcpkg recommendations and install vcpkg as a subfolder.  If you want to use "classic mode" or install vcpkg somewhere else, you're on your own.

If you don't want to use vcpkg, try the [manual instructions](BUILDING_WINDOWS_MANUAL.md).

First, bootstrap vcpkg.  From the root folder of your GameNetworkingSockets workspace:

```
> git clone https://github.com/microsoft/vcpkg
> .\vcpkg\bootstrap-vcpkg.bat
```

For the following commands, it's important to run them from a Visual Studio command prompt so that the compiler can be located.

You can obtain the dependent packages into your local `vcpkg` folder as an explicit step.  This is optional because the `cmake` command line below will also do it for you, but doing it as a separate step can help isolate any problems.

```
> .\vcpkg\vcpkg install --triplet=x64-windows
```

If you want to use the libsodium backend, install the libsodium dependencies by adding `--x-feature=libsodium`.

Now run cmake to create the project files.  Assuming you have vcpkg in the recommended location as shown above, the vcpkg toolchain will automatically be used, so you do not need to explicitly set `CMAKE_TOOLCHAIN_FILE`.  A minimal command line might look like this:

```
> cmake -S . -B build -G Ninja
```

To build all the examples and tests and add P2P/ICE support via the WebRTC submodule, use something like this:

```
> cmake -S . -B build -G Ninja -DBUILD_EXAMPLES=ON -DBUILD_TESTS=ON -DUSE_STEAMWEBRTC=ON
```

Finally, build the projects:

```
> cd build
> ninja
```

## Mac OS X

Using [Homebrew](https://brew.sh)

### OpenSSL

```
$ brew install openssl
$ export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/opt/openssl/lib/pkgconfig
```
GameNetworkingSockets requries openssl version 1.1+, so if you install and link openssl but at compile you see the error ```Dependency libcrypto found: NO (tried cmake and framework)``` you'll need to force Brew to install openssl 1.1. You can do that like this:
```
$ brew install openssl@1.1
$ export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/opt/openssl@1.1/lib/pkgconfig
```

### protobuf

```
$ brew install protobuf
```


#!/usr/bin/env /bin/bash
set -euo pipefail

# Set the swift build configuration.
export BUILD_TYPE="RelWithDebInfo" # Options: Debug, Release, RelWithDebInfo, MinSizeRel

### Uncommenting the next line could help to debug issues or better understand the pipeline.
# set -x

export BUILD_SCRIPT_VERSION=1 # Helps the preparation script to warn in case of future changes.
export PREPARATION_SCRIPT_PATH="$(dirname "$0")/.env_prep"

# Ensure git submodules are initialised before building.
if git submodule status --recursive 2>/dev/null | grep -q '^-'; then
  echo "Submodules not initialised – running 'git submodule update --init --recursive'..."
  git submodule update --init --recursive
fi

if command -v swiftly >/dev/null 2>&1; then
  export SWIFTLY_PATH="$(command -v swiftly)"
elif [ -f "$HOME/.swiftly/bin/swiftly" ]; then                 # macOS default path
  export SWIFTLY_PATH="$HOME/.swiftly/bin/swiftly"
elif [ -f "$HOME/.local/share/swiftly/bin/swiftly" ]; then     # Linux default path
  export SWIFTLY_PATH="$HOME/.local/share/swiftly/bin/swiftly"
else
  echo "swiftly not found in PATH."
  echo "Install it from https://www.swift.org/download/"
  exit 1
fi

# This command will prepare the environment and create a swiftpm and a vscode basic configuration.
# On doing so, it might opt to overwrite some of the existing files. If you are customizing your
# environment, please inspect the preparation script dumped at PREPARATION_SCRIPT_PATH and source it
# manually after inspection. You can also use the following flags to disable parts of the preparation:
    #--disable-vscode-settings \
    #--disable-sourcekit-lsp-settings \
    #--disable-toolset \
    #--disable-swift-version \
    #--disable-install-dependencies \
"$SWIFTLY_PATH" run swift package prepare-rp2xxx-environment \
    "$@" \
    --dump-prep-script "$PREPARATION_SCRIPT_PATH" \
    --allow-writing-to-package-directory \
    --disable-vscode-settings \
    --disable-sourcekit-lsp-settings \
    --allow-network-connections all  # Used to download PicoSDK, toolchain and other dependencies.

# The preparation script is dumped to PREPARATION_SCRIPT_PATH so it can be inspected.
# Users can opt to place the output in a different location and source it here once inspected if preferred.
source "$PREPARATION_SCRIPT_PATH"

# Avoid linking lwIP/cyw43_lwip; Mongoose provides its own TCP/IP driver.
export CPICOSDK_pico2_w_IMPORTED_LIBS_MORE="pico_cyw43_arch_poll"
export CPICOSDK_pimoroni_pico_plus2_w_rp2350_IMPORTED_LIBS_MORE="pico_cyw43_arch_poll"

# Disable lwIP integration for cyw43_arch (Mongoose provides its own TCP/IP).
export EXTRA_CONFIG_PARAMS="$EXTRA_CONFIG_PARAMS -Xcc -DCYW43_LWIP=0"

# Keep SourceKit-LSP aligned with the embedded build configuration.
mkdir -p "${PACKAGE_PATH}/.sourcekit-lsp"
cat > "${PACKAGE_PATH}/.sourcekit-lsp/config.json" <<EOF
{
  "swiftPM": {
    "buildSystem": "native",
    "scratchPath": ".build",
    "configuration": "${SWIFT_BUILD_TYPE}",
    "triple": "${SWIFTPM_TRIPLE}",
    "toolsets": [
      "${TOOLSET_PATH}"
    ],
    "swiftCompilerFlags": [
      "-enable-experimental-feature",
      "Embedded"
    ],
    "cCompilerFlags": [
      "--sysroot",
      "${SDK_PATH}",
      "-DCYW43_LWIP=0"
    ]
  },
  "backgroundIndexing": false,
  "backgroundPreparationMode": "enabled"
}
EOF

# Make sure the selected swift toolchain is installed.
"$SWIFTLY_PATH" install

# Builds the library using swiftpm. This is where the application code is compiled.
"$SWIFTLY_PATH" run swift build -v \
    --build-system native \
    --configuration $SWIFT_BUILD_TYPE \
    --toolset $TOOLSET_PATH \
    --triple $SWIFTPM_TRIPLE \
    $EXTRA_CONFIG_PARAMS            # This allows passing extra parameters from the command line.
                                    # Used for adding debugging flags based on the cmake configuration.

# Merge Swift embedded runtime libraries (UnicodeDataTables, Concurrency) into libApp.a
# so the CMake final link step can resolve symbols they provide.
TOOLCHAIN_PATH="$("$SWIFTLY_PATH" use -p)"
SWIFT_EMBEDDED_LIBS_DIR="${TOOLCHAIN_PATH}/usr/lib/swift/embedded/${SWIFTPM_TRIPLE}"

LIBAPP_PATH=".build/${SWIFTPM_TRIPLE}/${SWIFT_BUILD_TYPE}/lib${SWIFTPM_PRODUCT}.a"
LLVM_AR="${TOOLCHAIN_PATH}/usr/bin/llvm-ar"

if [ -d "$SWIFT_EMBEDDED_LIBS_DIR" ] && [ -f "$LIBAPP_PATH" ] && [ -x "$LLVM_AR" ]; then
    MERGE_TMPDIR=$(mktemp -d)
    trap "rm -rf '$MERGE_TMPDIR'" EXIT
    for lib in libswiftUnicodeDataTables.a; do
        [ -f "$SWIFT_EMBEDDED_LIBS_DIR/$lib" ] || continue
        LIBDIR="$MERGE_TMPDIR/${lib%.a}"
        mkdir -p "$LIBDIR"
        (cd "$LIBDIR" && "$LLVM_AR" x "$SWIFT_EMBEDDED_LIBS_DIR/$lib")
        "$LLVM_AR" rcs "$LIBAPP_PATH" "$LIBDIR"/*.o
        echo "  Merged $lib into $LIBAPP_PATH"
    done
fi

# Here the application code is linked with the PicoSDK and other imported libraries to produce
# the final binary that can be flashed to the target device. An UF2 and ELF file are produced.
finalize_rp2xxx_binary "$@"

# Flash the produced binary to the target device if requested.
flash_if_needed "$@"

#!/usr/bin/env python3
"""Workaround for openwrt/packages#27485 (rust host build failure).

Root cause:
  - rust >= 1.90 ships Cargo.toml.orig files inside vendor/ of the official
    source tarball (introduced by rust-lang/cargo@29ecb7f); cargo's bootstrap
    needs them for checksum verification.
  - OpenWrt's scripts/patch-kernel.sh deletes ALL *.orig files during the
    Patch step, mistaking them for patch backups.
  - Result: `failed to calculate checksum of:
    .../vendor/cc-*/Cargo.toml.orig: No such file or directory`, and the host
    rust build fails deterministically.

Fix (same approach as openwrt/packages PR #27487, which was never backported
to openwrt-24.10): override Host/Patch in the feed's rust Makefile with a
version that still applies patches but skips the *.orig deletion.

Usage: run from the openwrt build root AFTER `./scripts/feeds install -a`:
    python3 firmware_build/fix-rust-orig.py
Idempotent: exits 0 without changes if the override is already present.
"""

import sys

RUST_MAKEFILE = "feeds/packages/lang/rust/Makefile"
ANCHOR = "$(eval $(call HostBuild))"

OVERRIDE = """\
# Workaround openwrt/packages#27485: patch-kernel.sh deletes ALL *.orig
# files, but rust>=1.90 ships Cargo.toml.orig in vendor/ which cargo needs
# for checksum verification. Same approach as upstream PR #27487.
define Host/Patch
\t$(if $(HOST_QUILT),rm -rf $(HOST_BUILD_DIR)/patches; mkdir -p $(HOST_BUILD_DIR)/patches)
\t$(if $(HOST_QUILT),$(call PatchDir/Quilt,$(HOST_BUILD_DIR),$(HOST_PATCH_DIR),))
\t$(if $(HOST_QUILT),touch $(HOST_BUILD_DIR)/.quilt_used)
\t$(if $(HOST_QUILT),,$(if $(wildcard $(HOST_PATCH_DIR)/*.patch), \\
\t\t$(foreach p,$(sort $(wildcard $(HOST_PATCH_DIR)/*.patch)), \\
\t\t\techo "Applying patch $(notdir $p)" ; \\
\t\t\t$(PATCH) -f -p1 -d $(HOST_BUILD_DIR) < $p || \\
\t\t\t{ echo "Patch failed! Please fix: $(notdir $p)!"; exit 1; } ; \\
\t\t) \\
\t))
endef

"""


def main() -> int:
    try:
        with open(RUST_MAKEFILE) as f:
            src = f.read()
    except OSError as exc:
        print(f"ERROR: cannot read {RUST_MAKEFILE}: {exc}", file=sys.stderr)
        return 1

    if "define Host/Patch" in src:
        print("rust Makefile already has a Host/Patch override, nothing to do")
        return 0

    if ANCHOR not in src:
        print(f"ERROR: anchor {ANCHOR!r} not found in {RUST_MAKEFILE}",
              file=sys.stderr)
        return 1

    with open(RUST_MAKEFILE, "w") as f:
        f.write(src.replace(ANCHOR, OVERRIDE + ANCHOR, 1))
    print(f"Host/Patch override applied to {RUST_MAKEFILE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

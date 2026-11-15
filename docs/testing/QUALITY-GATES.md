# OneBookOS quality gates

| Level | Validation | What it proves |
| --- | --- | --- |
| G0 | Python standard-library architecture tests + syntax checks | Repository and source contract only |
| G1 | Compile/build on Ubuntu 24.04 runner | Build dependencies and compilation |
| G2 | ISO checksums, GRUB boot catalog, file presence | ISO integrity, not runtime |
| G3 | Headless and graphical QEMU process/session boot | VM startup, not aesthetics |
| G4 | Real framebuffer screenshots and visual comparison | Tested-screen visual appearance |
| G5 | Pointer, keyboard, window, notch, apps and service interaction | Real controls work |
| G6 | Installer on disposable VM disk, reboot/login, recovery | VM installation path |
| G7 | Actual Intel/AMD/NVIDIA and selected Galaxy Book device tests | Only tested hardware |
| G8 | Regression, accessibility, security, update/rollback and release review | Release candidate gate |

A successful G0/G3 is NOT an approved graphical ISO. Screenshots from QEMU do NOT certify real GPU or touch hardware. Never overwrite a personal disk or silently promote Live auto-login into the installed system.

## Stage 1 acceptance
- Existing repository inventoried, old GNOME and labwc preview unchanged.
- Manifest parses; source paths and design/roadmap documents exist.
- New source checks pass in GitHub Actions.
- Work is proposed in a draft PR, not silently merged.
- No ISO built or released by this stage.

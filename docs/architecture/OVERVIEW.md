# OneBookOS — architecture baseline, stage 1

**State:** design and repository foundation. Not a completed rewrite or a new ISO.

## Current repository inventory

| Source | Actual technology | Role |
| --- | --- | --- |
| build/ and overlay/ | Ubuntu 24.04 Live, GNOME Shell extension | Historical baseline; preserve |
| onebookui/ | Ubuntu 24.04 Live, greetd, labwc, GTK3 and gtk-layer-shell | Experimental Wayland preview; preserve |
| .github/workflows/build-iso.yml | GNOME ISO workflow | Historical CI |
| .github/workflows/onebookui-iso.yml | Wayland ISO and QEMU smoke tests | Preview CI |
| README.md | Long-term product vision proposing KWin/Qt6 | Aspirational, not necessarily implemented |

The current labwc Wayland preview already has a shell and QEMU startup tests. These do not establish UI fidelity, real GPU compatibility, a safe installer, or real hardware support.

## Planned module boundaries

- **Shell:** desktop, Start, divided bottom taskbar, black Dynamic Notch, notifications and session lifecycle.
- **UI Kit:** design tokens, scalable original icons, widget library, standard controls, animation system and accessibility.
- **Apps:** independent Files, Terminal, Settings, Store, Task Manager and later built-in apps; app failure should not terminate shell/compositor.
- **Services:** small adapters to NetworkManager, BlueZ, PipeWire/WirePlumber, UPower, UDisks2 and notification buses. Unsupported operations show errors; never fake success.
- **Installer:** future Calamares-backed install, explicit disk selection and confirmation; never transfer Live auto-login to installed accounts.
- **Display engine:** production compositor selection remains open. Compare candidates on effects, DPI, input, multi-monitor, recovery and hardware compatibility in stage 2.

## Reliability and security constraints

1. The compositor must survive a shell crash; retain an accessible recovery console or alternate session.
2. UI runs unprivileged. Use policy-authorized system services for actions requiring privilege.
3. No automatic destructive disk operations and no real-disk tests in CI.
4. Visual quality requires screenshots of a running desktop, not only design mockups or a process-alive marker.
5. All hardware support claims require explicitly documented tests.
6. Keep main unchanged until a focused pull request passes checks and is reviewed.

Read the design specification, 16-stage roadmap, technology decisions and quality gates before new implementation.

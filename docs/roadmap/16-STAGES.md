# OneBookOS — 17-stage delivery plan

**Rule:** each stage has a focused PR, tests, screenshots when visual, and documented exit criteria. More than one app in a stage means separate small PRs.

| Stage | Scope | Exit criterion |
| --- | --- | --- |
| 01 | Foundation, architecture, repository safety, lightweight CI | Verified manifest, docs and reviewable PR; no ISO change |
| 02 | Display engine comparison | Two compositor/toolkit paths evaluated with reproducible tests |
| 03 | Session and basic shell | Real Wayland desktop, window launch, recovery path |
| 04 | Design system | Shared tokens, original icons and components matching concept |
| 05 | Start and taskbar | Center Start, left/right bars, bottom-right date/time, real interactions |
| 06 | Dynamic Notch | Black integrated panel, tabs, transitions and focus handling |
| 07 | Wallpaper & Widgets | Original lavender/blue wallpaper and One UI-inspired desktop widget appearance; interactive foundations |
| 08 | Motion engine | Window/shell animations, reduced motion and performance captures |
| 09 | Widget set I | System, Media, Weather, Battery, Notes connected to real data |
| 10 | Widget set II | Calendar, Storage, Connectivity, Screen/Audio, Scenes functional |
| 11 | Files and Terminal | Real file manager and terminal functionality |
| 12 | Settings and services | Real system settings and meaningful error states |
| 13 | Store and update path | Install/uninstall/update behavior and rollback safety design |
| 14 | Additional native apps | Media, Gallery, Calendar, Viewer, Task Manager, Notes in separate PRs |
| 15 | Live ISO and Calamares | QEMU live boot and install to disposable virtual disk |
| 16 | PC and Galaxy Book support | Intel/AMD/NVIDIA, HiDPI, touch, power and audio test matrix |
| 17 | Quality and release candidate | Regression, install/recovery, visual and hardware evidence |

Planned milestones: 0.1 after stages 1–3, 0.2 after 4–5, 0.3 after 6–8, 0.4 after 9–10, 0.5 after 11–12, 0.6 after 13–14, 0.7 after 15, 0.8–0.9 after 16–17. Release 1.0 only when all mandatory release tests pass.

Branch strategy: main stays a known baseline; onebookui-rewrite is integration; feature/stage-NN-description branches contain isolated changes. Never release a new ISO as stable on the basis of compilation alone.

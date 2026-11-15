# OneBookOS — architecture decisions

### ADR-001: Preserve both legacy implementations
Accepted. Keep build/ and overlay/ GNOME alpha as historical code. Keep onebookui/ labwc/GTK3 preview intact for comparison. Work in a separate branch: onebookui-rewrite.

### ADR-002: Do not prematurely select a production compositor
Accepted. The current preview runs labwc/GTK3, while the older top-level README proposes KWin/Qt6. Neither is a verified final architecture. Stage 2 evaluates compositor and toolkit combinations with technical tests before committing to one.

### ADR-003: Visual reference comes before visual code
Accepted. The approved concept specifies the central Start, bottom taskbar segments, date/time at lower right, a single black top-edge notch and original colorful squircle icons. Screenshots from generated concepts are design references, not proof of running code. Avoid copying proprietary Apple or Samsung assets.

### ADR-004: CI assurance levels must not be confused
Accepted. Source tests do not prove an ISO. ISO boot does not prove actual pixels. A screenshot does not prove interactions or real-hardware compatibility. These are distinct release gates.

### ADR-005: Product safety
Accepted. Live-session automatic login is for disposable images only. Installation on a real disk requires partition confirmation, authenticated account creation, recovery and physical-machine tests.

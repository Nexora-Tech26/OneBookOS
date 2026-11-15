# OneBookUI 8 — approved visual direction

This page records user-approved design constraints for the future shell. It does not claim the current ISO looks this way.

## Desktop
- Purple/indigo/blue original flowing wallpaper, restrained magenta highlights, crisp typography.
- Compact layout. **Three distinct bottom elements:** left taskbar, exactly centered Start button, right taskbar with date and time at far right.
- No duplicate top-right controls, floating weather/media control stack, or permanent system-menu panel.
- Original colorful rounded squircle application icons inspired by Samsung One UI, never Apple Photos/Music icon copies; no manufacturer affiliation implied.
- Centered compact frosted Start menu with search, pinned apps, recent files, navigation, and power action.
- Coherent window titlebars with small working minimize, maximize/restore and close controls.

## Dynamic Notch
- **Collapsed:** small black capsule attached to top center, without text. Keep battery information minimal where appropriate.
- **Expanded:** same black shape enlarges seamlessly from top screen edge. Never a separate translucent popup.
- Tabs inside the notch: Status, Media, Controls, Connections, Devices, Notifications.
- Weather, media player, brightness/volume, Wi-Fi, Bluetooth and notifications appear INSIDE the expanded notch.

## Motion and accessibility
- Aim for smooth animations on supported 60 Hz or higher displays; suggested interaction durations 150–300 ms must be measured.
- GPU/compositor support where available, reduced-motion option, keyboard and pointer access, performance fallback when blur is expensive.
- No claim of 60/120 FPS before benchmarks, no fake system controls.

## Ten interactive widgets
1. System Monitor — live radial CPU/GPU/RAM meters.
2. Media Control — playback, seek and queue.
3. Weather — forecasts and location.
4. Battery & Power — radial charge and power modes.
5. Quick Notes — editable persistent notes.
6. Calendar & Tasks — date selection and task management.
7. Storage — disk occupancy and category drill-down.
8. Connectivity — Wi-Fi, Bluetooth and device list.
9. Screen & Audio — radial brightness and volume dials.
10. Scenes & Automation — saved work/gaming/focus routines.

## Visual acceptance
A visual-change PR must include a screenshot from the actual running preview, a comparison with the approved concept, HiDPI/text sharpness inspection, and checks of minimized, hovered and expanded states. A generated illustration alone does not satisfy acceptance.

# OneBookOS

### A new perspective on the Linux desktop.

**Modern design. Intelligent hardware management. Reliable performance. Built on Ubuntu.**

OneBookOS (OBOS) is an independent, Ubuntu-based Linux distribution designed to bring together the reliability of Linux, an elegant desktop experience inspired by Samsung One UI, and a unified ecosystem of applications and productivity tools.

Our mission is simple: **make Linux beautiful, accessible, fast, stable, and enjoyable for everyone.**

OneBookOS is designed with particular attention to Samsung Galaxy Book computers while aiming to support a wide range of compatible laptops and desktop PCs.

> **Development Status: Early Development**
>
> OneBookOS is currently being developed. The first bootable ISO, complete desktop environment, hardware compatibility database, and production-ready features are planned or in progress. Features described in this document represent the project vision and technical targets unless explicitly marked as implemented.

---

## 01. Our Vision

We believe a desktop operating system should be powerful without being complicated, beautiful without sacrificing performance, and customizable without losing its identity.

OneBookOS aims to deliver:

- A premium and consistent user experience.
- A responsive desktop with smooth animations and modern visual effects.
- Reliable performance on supported hardware.
- Automatic hardware detection and driver diagnostics.
- Simple and secure software installation.
- A complete collection of everyday applications.
- Advanced development and productivity capabilities.
- Practical integration with compatible Galaxy devices.
- Easy system recovery and maintenance.
- An accessible environment for both beginners and advanced users.

**OneBookOS is not just a desktop theme. Our goal is to create a complete Linux distribution with its own identity, system components, applications, and long-term development roadmap.**

---

## 02. Core Principles

### Performance First

Every system component should be designed to minimize unnecessary resource consumption.

Our performance goals include:

- Efficient CPU and GPU utilization.
- GPU-accelerated desktop animations.
- Fast application startup.
- Low background resource usage.
- Responsive multitasking.
- Optimized memory management.
- Smooth operation on both 60 Hz and 120 Hz displays.
- Intelligent power-saving behavior.

### Stability by Design

Stability is a fundamental requirement, not an optional feature.

OneBookOS is designed around:

- A stable Ubuntu LTS foundation.
- Well-maintained Linux components.
- Isolated application processes where appropriate.
- Controlled system updates.
- Hardware compatibility validation.
- Automated regression testing.
- Crash reporting and diagnostics.
- Recovery mechanisms for failed updates.

### Security and Privacy

OneBookOS aims to provide a secure environment through:

- Linux user permissions and process isolation.
- Trusted software repositories.
- Verified update packages.
- Application sandboxing where supported.
- Secure system defaults.
- Clear permission management.
- Optional disk encryption.
- Privacy-conscious system services.

Security-sensitive functionality must undergo testing before being considered production-ready.

---

## 03. System Architecture

OneBookOS is planned as a Linux distribution built on Ubuntu.

| Component | Planned technology |
|---|---|
| Operating system base | Ubuntu LTS |
| Kernel | Linux |
| Display protocol | Wayland |
| Window management | KWin |
| Desktop interface | Qt 6 / QML |
| System utilities | Python, C++ and Qt |
| Audio | PipeWire |
| Network management | NetworkManager |
| Bluetooth | BlueZ |
| Package management | APT |
| Firmware management | fwupd |
| System initialization | systemd |
| Display manager | SDDM or compatible alternative |
| Installation image | Bootable Ubuntu-based ISO |
| Build automation | GitHub Actions |

The architecture may evolve as implementation and compatibility testing progress.

### Modular Architecture

OneBookOS is intended to separate major system components into independent modules.

This approach is designed to improve maintainability, fault isolation, testing, and performance.

Planned components include:

- `obos-core` — operating system integration and shared services.
- `obos-shell` — desktop environment and shell.
- `obos-design` — visual assets and design components.
- `obos-device-center` — hardware detection and diagnostics.
- `obos-settings` — system configuration.
- `obos-store` — application management.
- `obos-update` — system updates.
- `obos-recovery` — diagnostics and recovery tools.
- `obos-apps` — first-party applications.
- `obos-build` — distribution image generation.

---

## 04. OneBook Desktop

### Inspired by One UI. Designed for the desktop.

OneBook Desktop is the planned graphical environment of OneBookOS.

Its design direction takes inspiration from Samsung One UI while maintaining an independent visual identity.

The desktop experience is intended to include:

- Clean and modern visual design.
- Soft gradients and carefully controlled transparency.
- Consistent spacing and typography.
- Rounded windows and interface components.
- Smooth GPU-accelerated animations.
- A modern application launcher.
- A compact taskbar and application dock.
- Integrated notifications and quick controls.
- Flexible window management.
- Light and dark appearance modes.
- Multimonitor and high-DPI display support.

### OneBook Start

The application launcher will provide quick access to installed applications, recently used files, search, system actions, and essential settings.

### OneBook Dock

The dock is designed for efficient application switching and management.

Planned capabilities include pinned applications, running application indicators, context menus, drag-and-drop organization, and optional automatic hiding.

### Dynamic Notch

Dynamic Notch is a compact, expandable interaction area positioned near the upper edge of the screen.

It is designed to provide contextual information without permanently occupying large amounts of desktop space.

Potential functionality includes:

- Media playback controls.
- Clipboard history.
- Recent downloads.
- Notifications.
- Volume controls.
- Device connection status.
- File transfer progress.
- Active application information.
- Quick system actions.

Dynamic Notch should automatically collapse when no longer needed and remain optional for users who prefer a traditional desktop layout.

---

## 05. OneBook Design System

OneBookOS aims to maintain a recognizable, consistent design language across its system interface and first-party applications.

The official design system will define:

- Icon geometry and visual proportions.
- Gradients and color palettes.
- Typography and font scaling.
- Window and component shapes.
- Shadows and transparency.
- Animation duration and motion curves.
- Accessibility standards.
- Application navigation patterns.
- Dialogs, menus, buttons, sliders, and controls.

### Personalization Without Compromising Identity

Users will be able to customize supported aspects of the desktop, including:

- Wallpapers.
- Light and dark modes.
- Accent colors.
- Desktop widget placement.
- Dock configuration.
- Taskbar preferences.
- Dynamic Notch behavior.
- Accessibility settings.
- Display scaling.
- Animation preferences.

The official OneBook visual identity will remain the default experience.

Advanced users may still customize their own Linux installations beyond the standard settings interface.

---

## 06. OneBook Device Center

### Intelligent hardware management.

OneBook Device Center is a planned hardware diagnostics and compatibility management application.

Its purpose is to simplify device configuration, especially on laptops with hardware-specific features.

### Planned Capabilities

**Hardware Detection**

- Processor identification.
- Graphics hardware detection.
- Memory and storage information.
- Wi-Fi and Bluetooth adapters.
- Audio devices.
- Touchpads and keyboards.
- Cameras.
- Battery and charging hardware.
- Firmware and BIOS/UEFI information.

**Driver Diagnostics**

- Identify active kernel modules.
- Detect potentially missing firmware.
- Check supported driver packages.
- Report device initialization failures.
- Recommend compatible packages from trusted sources.
- Recheck device functionality after updates.

**System Health**

- Battery information.
- Storage health indicators.
- Thermal monitoring where available.
- Device error reports.
- Firmware update availability.
- Hardware compatibility status.

OneBook Device Center will not guarantee driver availability for unsupported hardware or attempt to install unverified drivers automatically.

---

## 07. Samsung Galaxy Book Compatibility

Samsung Galaxy Book devices are a priority hardware family for OneBookOS.

The project aims to develop compatibility profiles for different generations and configurations, potentially including:

- Galaxy Book and Galaxy Book2.
- Galaxy Book3 series.
- Galaxy Book4 series.
- Galaxy Book5 series.
- Future Galaxy Book models.

Compatibility will be evaluated for individual hardware configurations rather than assumed for an entire product generation.

### Galaxy-Specific Features

Where supported by Linux drivers and hardware interfaces, OneBookOS aims to provide:

- Function-key support.
- Display brightness management.
- Battery charging controls.
- Power profiles.
- Keyboard backlight controls.
- Touchscreen functionality.
- S Pen support.
- Sleep and resume reliability.
- Hardware diagnostics.

ARM-based Galaxy Book devices may require a separate platform-specific implementation.

**Important:** OneBookOS is an independent project and is not affiliated with, endorsed by, or officially supported by Samsung Electronics.

Samsung, Galaxy, Galaxy Book, and One UI are trademarks of their respective owners.

---

## 08. OneBook Applications

OneBookOS aims to provide a unified collection of first-party applications.

### System Applications

| Application | Purpose |
|---|---|
| OneBook Files | File and folder management |
| OneBook Settings | System configuration |
| OneBook Terminal | Command-line environment |
| OneBook Calendar | Events and scheduling |
| OneBook Clock | Alarms, timers and stopwatch |
| OneBook Calculator | Standard and scientific calculations |
| OneBook Notes | Notes and simple documents |
| OneBook Music | Audio library and playback |
| OneBook Photos | Image browsing and management |
| OneBook Device Center | Hardware and driver diagnostics |
| OneBook Store | Application management |
| OneBook Update | System maintenance and updates |

### OneBook Office

The planned OneBook Office suite will provide integrated productivity tools:

- **OneBook Docs** — document editing and formatting.
- **OneBook Sheets** — spreadsheets, formulas, and data analysis.
- **OneBook Presentations** — slide creation and presentation.
- **OneBook Database** — structured data management.
- **OneBook PDF** — PDF viewing and editing.
- **OneBook Notes** — fast note-taking and organization.

File format compatibility, collaborative editing, and advanced features will be developed incrementally.

### OneBook Code Studio

OneBook Code Studio is the planned native development environment for OneBookOS.

Its intended capabilities include:

- Project and workspace management.
- Integrated terminal.
- Syntax highlighting.
- Code completion.
- Multiple programming languages.
- Git integration.
- Debugging tools.
- Extensions.
- Code navigation.
- Search and replace.
- Configurable developer workflows.

Existing Linux IDEs and editors will remain available.

---

## 09. OneBook Store

OneBook Store will provide a unified interface for discovering, installing, updating, and removing applications.

The planned system will prioritize established Linux package technologies rather than introducing an unnecessary custom package format.

Goals include:

- Application discovery.
- Search and categories.
- Application details.
- Installation progress.
- Update notifications.
- Safe removal.
- Package integrity checks.
- Clear permission information.
- Trusted distribution channels.

Where appropriate, Flatpak support may be considered alongside Ubuntu's APT infrastructure.

---

## 10. Updates and Recovery

### OneBook Update

System updates must be predictable and reliable.

The planned update architecture includes:

- Security updates.
- Operating system package updates.
- First-party application updates.
- Firmware update integration.
- Update verification.
- Error reporting.
- Clear restart requirements.
- Testing before major releases.

### OneBook Recovery

OneBook Recovery aims to reduce the impact of failed updates and configuration errors.

Potential functionality includes:

- Recovery boot options.
- System health checks.
- Diagnostic log collection.
- Safe recovery procedures.
- Configuration reset.
- Backup integration.
- Rollback functionality where supported by the underlying filesystem and update architecture.

A recovery feature will only be advertised as available after it has been implemented and validated.

---

## 11. Performance Targets

The following values represent design objectives, not current benchmark results.

| Metric | Development target |
|---|---|
| Desktop responsiveness | Smooth interactive performance |
| Animation frame rate | 60 FPS; 120 FPS on supported hardware |
| Idle memory consumption | Target below 1.5 GB |
| Start menu responsiveness | Target below 100 ms |
| Boot time on supported SSDs | Target 10–20 seconds |
| Application isolation | A single app crash should not terminate the desktop |
| Recovery | Reliable recovery paths for critical failures |

Actual results will depend on hardware, drivers, selected packages, and system configuration.

Performance testing will be an essential part of the release process.

---

## 12. Building OneBookOS

OneBookOS is intended to use reproducible, automated build workflows where practical.

The planned pipeline is:

```text
Source Repository
       |
       v
Dependency Validation
       |
       v
Ubuntu Base Preparation
       |
       v
Install OBOS Packages
       |
       v
Apply System Configuration
       |
       v
Configure Desktop Session
       |
       v
Generate Bootable ISO
       |
       v
Virtual Machine Testing
       |
       v
Publish Verified Build
```

### GitHub Actions

GitHub Actions is the intended build automation platform.

The workflow should:

1. Prepare a compatible Ubuntu build environment.
2. Install required build tools.
3. Assemble the Ubuntu-based filesystem.
4. Apply OneBookOS packages and configuration.
5. Generate a bootable ISO image.
6. Perform build validation.
7. Upload the image as a downloadable artifact.

Build success does not automatically mean the image has passed boot, installation, or hardware compatibility testing.

### Installation

The planned installation methods are:

- Live USB.
- Virtual machine.
- Installation alongside an existing operating system, where supported.
- Installation on a dedicated disk.

**Do not install early development builds on a computer containing important data without verified backups.**

---

## 13. Development Roadmap

### Phase 1 — OneBookOS Core

- [ ] Establish Ubuntu base.
- [ ] Create automated ISO build workflow.
- [ ] Produce first bootable ISO.
- [ ] Validate boot in a virtual machine.
- [ ] Configure basic desktop session.
- [ ] Verify networking, audio and storage support.

### Phase 2 — Desktop Alpha

- [ ] Implement OneBook shell.
- [ ] Build the application launcher.
- [ ] Implement Dock and taskbar.
- [ ] Add Dynamic Notch.
- [ ] Establish visual design system.
- [ ] Integrate notifications and settings.

### Phase 3 — System Integration

- [ ] Implement Device Center.
- [ ] Create hardware detection service.
- [ ] Add driver and firmware diagnostics.
- [ ] Introduce system update UI.
- [ ] Add crash reporting.
- [ ] Develop recovery tools.

### Phase 4 — Applications

- [ ] OneBook Files.
- [ ] OneBook Settings.
- [ ] OneBook Store.
- [ ] OneBook Office.
- [ ] OneBook Code Studio.
- [ ] Multimedia and everyday applications.

### Phase 5 — Public Beta

- [ ] Expand hardware compatibility testing.
- [ ] Resolve critical crashes and regressions.
- [ ] Optimize performance and battery usage.
- [ ] Test installation and recovery procedures.
- [ ] Publish release documentation.
- [ ] Gather community feedback.

### Phase 6 — OneBookOS 1.0

The first stable release will be considered only when core functionality, installation, security updates, recovery, and supported hardware compatibility reach acceptable quality standards.

---

## 14. Contributing

OneBookOS is intended to encourage constructive contributions from developers, designers, testers, translators, and Linux enthusiasts.

Potential contribution areas include:

- Desktop development.
- Qt/QML components.
- Linux system integration.
- Hardware compatibility testing.
- Application development.
- Performance optimization.
- Security review.
- Accessibility.
- Documentation.
- Translations.
- Bug reports.

Contribution guidelines and development workflows will be published as the repository matures.

---

## 15. Quality Standards

A successful OneBookOS release must do more than look polished.

Our release requirements will prioritize:

**Reliability:** Core services should operate predictably and recover gracefully from failures.

**Performance:** The desktop must remain responsive on supported hardware.

**Usability:** Everyday tasks should not require unnecessary technical knowledge.

**Consistency:** First-party applications should follow the same design principles.

**Security:** Packages, updates, and elevated operations must be handled responsibly.

**Compatibility:** Supported hardware should be tested and documented.

**Maintainability:** Components should be modular, documented, and testable.

---

## 16. Project Status

| Area | Status |
|---|---|
| Project vision and requirements | Defined |
| Python desktop prototype | Experimental |
| Ubuntu-based distribution | Planned |
| Automated ISO build | Not yet verified |
| Qt/QML desktop | Planned |
| Device Center | Planned |
| Galaxy Book compatibility profiles | Planned |
| OneBook Store | Planned |
| OneBook Office | Planned |
| Stable public release | Not available |

Development status will be updated as implementation progresses.

---

## 17. Licensing and Trademarks

The project license will be selected and published before public source distribution is finalized.

Third-party components retain their respective licenses and copyright notices. Ubuntu, Linux, Qt, and other upstream technologies have their own licensing requirements.

OneBookOS is an independent operating system project.

It is not an official Samsung product and is not affiliated with Samsung Electronics, Canonical, or Ubuntu.

Use of Samsung-related names in this README is descriptive and does not imply sponsorship, endorsement, or official compatibility certification.

---

## 18. The Future of OneBookOS

We are building OneBookOS around a long-term vision: a Linux system that combines the freedom of open computing with the polish, convenience, and reliability expected from modern consumer technology.

A system that adapts to its users.

A system that makes hardware management easier.

A system that values both design and performance.

A system that works for everyday users, students, developers, and enthusiasts.

**OneBookOS — Designed for people. Powered by Linux. Built for what comes next.**

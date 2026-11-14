import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// OneBookOS 0.2 — GNOME Shell 46 extension. GNOME manages windows and sessions;
// this extension provides an independent dock and an interactive top-edge hub.
export default class OneBookDesktop extends Extension {
    enable() {
        this._signals = [];
        this._timers = [];
        this._expanded = false;
        this._buildDock();
        this._buildNotch();
        Main.layoutManager.addChrome(this._dock, {affectsStruts: false, trackFullscreen: true});
        Main.layoutManager.addChrome(this._notch, {affectsStruts: false, trackFullscreen: true});
        Main.panel.hide();
        this._signals.push([Main.layoutManager, Main.layoutManager.connect('monitors-changed', () => this._relayout())]);
        this._signals.push([this._dock, this._dock.connect('notify::width', () => this._relayout())]);
        this._signals.push([this._notch, this._notch.connect('notify::width', () => this._relayout())]);
        this._clockTick();
        this._timers.push(GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 15, () => this._clockTick()));
        this._relayout();
        // QEMU acceptance marker: emitted from extension.enable(), not a system service.
        try { GLib.file_set_contents('/tmp/obos-gnome-extension-ready', 'onebookos-0.2'); } catch (e) { logError(e); }
    }
    _icon(name, size = 25) {
        return new St.Icon({icon_name: name, icon_size: size, style_class: 'obos-symbol'});
    }
    _button(iconName, tooltip, action) {
        const button = new St.Button({
            style_class: 'obos-app',
            can_focus: true,
            track_hover: true,
            child: this._icon(iconName),
            accessible_name: tooltip,
        });
        button.connect('clicked', action);
        return button;
    }
    _launch(id) {
        const app = Shell.AppSystem.get_default().lookup_app(id);
        if (app)
            app.activate();
        else
            Main.notify('OneBookOS', 'Application unavailable: ' + id);
    }
    _buildDock() {
        this._dock = new St.BoxLayout({style_class: 'obos-dock-root', reactive: true, track_hover: true});
        const left = new St.BoxLayout({style_class: 'obos-dock-side'});
        for (const [icon, name, id] of [
            ['system-file-manager-symbolic', 'Files', 'org.gnome.Nautilus.desktop'],
            ['utilities-terminal-symbolic', 'Terminal', 'org.gnome.Terminal.desktop'],
            ['view-app-grid-symbolic', 'Applications', null],
            ['emblem-system-symbolic', 'Settings', 'org.gnome.Settings.desktop'],
        ])
            left.add_child(this._button(icon, name, () => id ? this._launch(id) : Main.overview.showApps()));
        this._dock.add_child(left);

        const startIcon = new St.Icon({
            gicon: Gio.icon_new_for_string(this.path + '/icons/onebook.svg'),
            icon_size: 29,
        });
        const start = new St.Button({
            style_class: 'obos-start',
            can_focus: true,
            accessible_name: 'OneBookOS Start',
            child: startIcon,
        });
        start.connect('clicked', () => Main.overview.showApps());
        this._dock.add_child(start);

        const right = new St.BoxLayout({style_class: 'obos-dock-side'});
        for (const [icon, name, id] of [
            ['accessories-calculator-symbolic', 'Calculator', 'org.gnome.Calculator.desktop'],
            ['org.gnome.Software-symbolic', 'Software', 'org.gnome.Software.desktop'],
            ['audio-volume-high-symbolic', 'Sound settings', 'org.gnome.Settings.desktop'],
        ])
            right.add_child(this._button(icon, name, () => this._launch(id)));
        const clockBox = new St.BoxLayout({vertical: true, style_class: 'obos-clock-box'});
        this._timeLabel = new St.Label({style_class: 'obos-time', text: '00:00'});
        this._dateLabel = new St.Label({style_class: 'obos-date', text: 'OneBookOS'});
        clockBox.add_child(this._timeLabel);
        clockBox.add_child(this._dateLabel);
        const clockButton = new St.Button({child: clockBox, can_focus: true, accessible_name: 'Calendar'});
        clockButton.connect('clicked', () => Main.panel.statusArea.dateMenu?.menu.toggle());
        right.add_child(clockButton);
        this._dock.add_child(right);
    }
    _buildNotch() {
        this._notch = new St.BoxLayout({
            style_class: 'obos-notch-shell',
            reactive: true,
            track_hover: true,
            vertical: true,
        });
        const compact = new St.BoxLayout({style_class: 'obos-notch-compact', x_align: Clutter.ActorAlign.CENTER});
        compact.add_child(this._icon('media-playback-start-symbolic', 15));
        compact.add_child(new St.Label({text: 'OneBookOS', style_class: 'obos-notch-title', y_align: Clutter.ActorAlign.CENTER}));
        compact.add_child(new St.Label({text: '●', style_class: 'obos-notch-hint', y_align: Clutter.ActorAlign.CENTER}));
        this._compact = compact;
        this._notch.add_child(compact);

        const body = new St.BoxLayout({style_class: 'obos-notch-expanded', vertical: true});
        const heading = new St.Label({text: 'OneBook Hub', style_class: 'obos-notch-heading'});
        const subtitle = new St.Label({text: 'Your essentials, one gesture away', style_class: 'obos-notch-caption'});
        body.add_child(heading);
        body.add_child(subtitle);
        const shortcuts = new St.BoxLayout({style_class: 'obos-notch-shortcuts'});
        for (const [icon, text, action] of [
            ['preferences-system-symbolic', 'Settings', () => this._launch('org.gnome.Settings.desktop')],
            ['network-wireless-symbolic', 'Network', () => this._launch('org.gnome.Settings.desktop')],
            ['audio-volume-high-symbolic', 'Sound', () => this._launch('org.gnome.Settings.desktop')],
        ]) {
            const buttonBody = new St.BoxLayout({style_class: 'obos-hub-action'});
            buttonBody.add_child(this._icon(icon, 17));
            buttonBody.add_child(new St.Label({text, y_align: Clutter.ActorAlign.CENTER}));
            const button = new St.Button({child: buttonBody, can_focus: true, accessible_name: text});
            button.connect('clicked', action);
            shortcuts.add_child(button);
        }
        body.add_child(shortcuts);
        body.add_child(new St.Label({text: 'GNOME Shell 46  •  Ubuntu 24.04 LTS  •  Alpha 0.2', style_class: 'obos-metrics'}));
        this._expandedBody = body;
        this._notch.add_child(body);
        body.hide();

        this._signals.push([this._notch, this._notch.connect('notify::hover', () => {
            this._expanded = this._notch.hover;
            this._compact.visible = !this._expanded;
            this._expandedBody.visible = this._expanded;
            this._relayout();
        })]);
    }
    _clockTick() {
        const now = GLib.DateTime.new_now_local();
        this._timeLabel.set_text(now.format('%H:%M'));
        this._dateLabel.set_text(now.format('%a, %d %b'));
        return GLib.SOURCE_CONTINUE;
    }
    _relayout() {
        const monitor = Main.layoutManager.primaryMonitor;
        if (!monitor || !this._dock || !this._notch)
            return;
        this._dock.set_position(
            Math.round(monitor.x + (monitor.width - this._dock.width) / 2),
            Math.round(monitor.y + monitor.height - this._dock.height - 16)
        );
        this._notch.set_position(
            Math.round(monitor.x + (monitor.width - this._notch.width) / 2),
            monitor.y
        );
    }
    disable() {
        for (const timer of this._timers ?? [])
            GLib.Source.remove(timer);
        for (const [obj, id] of this._signals ?? [])
            obj.disconnect(id);
        this._timers = [];
        this._signals = [];
        this._dock?.destroy();
        this._notch?.destroy();
        this._dock = null;
        this._notch = null;
        Main.panel.show();
        try { Gio.File.new_for_path('/tmp/obos-gnome-extension-ready').delete(null); } catch {}
    }
}

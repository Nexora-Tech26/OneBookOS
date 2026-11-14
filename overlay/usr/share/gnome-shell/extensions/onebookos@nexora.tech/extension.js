import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import Shell from 'gi://Shell';
import Meta from 'gi://Meta';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// OneBookOS 0.2 — independent Start/menu/dock experience built for GNOME Shell 46.
// All chrome is owned and cleaned up by this extension. No duplicate GNOME app grid
// is invoked by the central Start button.
const CORE = [
    ['Files', 'org.gnome.Nautilus.desktop', 'files', 'System'],
    ['Settings', 'org.gnome.Settings.desktop', 'settings', 'System'],
    ['Terminal', 'org.gnome.Terminal.desktop', 'terminal', 'Developer'],
    ['Software', 'org.gnome.Software.desktop', 'store', 'System'],
    ['Calculator', 'org.gnome.Calculator.desktop', 'calculator', 'Utilities'],
    ['Text Editor', 'org.gnome.TextEditor.desktop', 'notes', 'Productivity'],
    ['System Monitor', 'org.gnome.SystemMonitor.desktop', 'monitor', 'System'],
    ['Image Viewer', 'org.gnome.Loupe.desktop', 'photos', 'Graphics'],
];
const CATEGORIES = ['All', 'Productivity', 'System', 'Developer', 'Utilities', 'Graphics', 'Other'];
const ANIMATION = 180;

export default class OneBookDesktop extends Extension {
    enable() {
        this._signals = [];
        this._timers = [];
        this._menuOpen = false;
        this._category = 'All';
        this._searchTerm = '';
        this._expanded = false;
        this._buildDock();
        this._buildMenu();
        this._buildNotch();
        for (const actor of [this._dock, this._startMenu, this._notch])
            Main.layoutManager.addChrome(actor, {affectsStruts: false, trackFullscreen: true});
        Main.panel.hide();
        this._connect(Main.layoutManager, 'monitors-changed', () => this._relayout());
        for (const actor of [this._dock, this._notch, this._startMenu])
            this._connect(actor, 'notify::width', () => this._relayout());
        this._connect(global.stage, 'captured-event', (_stage, event) => {
            if (!this._menuOpen)
                return Clutter.EVENT_PROPAGATE;
            if (event.type() === Clutter.EventType.KEY_PRESS && event.get_key_symbol() === Clutter.KEY_Escape) {
                this._hideMenu();
                return Clutter.EVENT_STOP;
            }
            if (event.type() === Clutter.EventType.BUTTON_PRESS || event.type() === Clutter.EventType.TOUCH_BEGIN) {
                const [x, y] = event.get_coords();
                if (!this._inActor(this._startMenu, x, y) && !this._inActor(this._dock, x, y))
                    this._hideMenu();
            }
            return Clutter.EVENT_PROPAGATE;
        });
        this._connect(Shell.AppSystem.get_default(), 'installed-changed', () => {
            if (this._startMenu)
                this._refreshApps();
        });
        this._clockTick();
        this._timers.push(GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 15, () => this._clockTick()));
        this._relayout();
        // Reached from inside the actual GNOME Shell extension, not only GDM.
        try { GLib.file_set_contents('/tmp/obos-gnome-extension-ready', 'onebookos-0.2-custom-start'); }
        catch (e) { logError(e); }
    }
    _connect(obj, name, fn) {
        const id = obj.connect(name, fn);
        this._signals.push([obj, id]);
        return id;
    }
    _blur(actor, radius = 24) {
        // GNOME Shell compositor backdrop blur (not an opacity-only imitation).
        // Falls back to translucent OneBook surfaces when unsupported by renderer.
        try {
            actor.add_effect(new Shell.BlurEffect({
                mode: Shell.BlurMode.BACKGROUND, radius, brightness: 0.94,
            }));
        } catch (e) { log('OneBookOS: backdrop blur disabled: ' + e.message); }
    }
    _icon(key, size = 26) {
        const filename = this.path + '/icons/' + key + '.svg';
        if (GLib.file_test(filename, GLib.FileTest.EXISTS))
            return new St.Icon({gicon: new Gio.FileIcon({file: Gio.File.new_for_path(filename)}), icon_size: size});
        return new St.Icon({icon_name: key, icon_size: size});
    }
    _text(text, style) {
        return new St.Label({text, style_class: style, y_align: Clutter.ActorAlign.CENTER});
    }
    _button(icon, title, action, style = 'obos-icon-button', size = 30) {
        const button = new St.Button({
            style_class: style, child: this._icon(icon, size),
            accessible_name: title, can_focus: true, track_hover: true,
        });
        this._connect(button, 'clicked', action);
        return button;
    }
    _launch(id) {
        const app = Shell.AppSystem.get_default().lookup_app(id);
        this._hideMenu();
        if (app) app.activate();
        else Main.notify('OneBookOS', 'Application is not installed: ' + id);
    }
    _allApps() {
        const installed = Shell.AppSystem.get_default().get_installed();
        return installed.filter(info => info.should_show() && info.get_name())
            .map(info => {
                const known = CORE.find(x => x[1] === info.get_id());
                return {name: info.get_name(), id: info.get_id(),
                    icon: known?.[2] ?? null, category: known?.[3] ?? 'Other', appInfo: info};
            })
            .sort((a,b) => a.name.localeCompare(b.name));
    }
    _inActor(actor, x, y) {
        if (!actor?.visible) return false;
        const [ax, ay] = actor.get_transformed_position();
        const [w, h] = actor.get_transformed_size();
        return x >= ax && x <= ax + w && y >= ay && y <= ay + h;
    }
    _buildDock() {
        this._dock = new St.BoxLayout({style_class: 'obos-dock-root', reactive: true, track_hover: true});
        const left = new St.BoxLayout({style_class: 'obos-dock-side'});
        this._blur(left, 16);
        for (const [name, id, icon] of [
            ['Files','org.gnome.Nautilus.desktop','files'],
            ['Terminal','org.gnome.Terminal.desktop','terminal'],
            ['Settings','org.gnome.Settings.desktop','settings'],
        ]) left.add_child(this._button(icon, name, () => this._launch(id)));
        this._dock.add_child(left);
        this._startButton = this._button('onebook', 'Open OneBook Start', () => this._toggleMenu(), 'obos-start', 34);
        this._dock.add_child(this._startButton);
        const right = new St.BoxLayout({style_class: 'obos-dock-side'});
        this._blur(right, 16);
        for (const [name, id, icon] of [
            ['Software','org.gnome.Software.desktop','store'],
            ['Calculator','org.gnome.Calculator.desktop','calculator'],
            ['System Monitor','org.gnome.SystemMonitor.desktop','monitor'],
        ]) right.add_child(this._button(icon, name, () => this._launch(id)));
        const status = this._button('controls', 'Open system settings', () => this._launch('org.gnome.Settings.desktop'));
        right.add_child(status);
        const clock = new St.BoxLayout({vertical: true, style_class: 'obos-clock-box'});
        this._timeLabel = this._text('00:00', 'obos-time');
        this._dateLabel = this._text('OneBookOS', 'obos-date');
        clock.add_child(this._timeLabel);
        clock.add_child(this._dateLabel);
        const clockButton = new St.Button({child: clock, can_focus: true, accessible_name: 'Date and calendar'});
        this._connect(clockButton, 'clicked', () => Main.panel.statusArea.dateMenu?.menu.toggle());
        right.add_child(clockButton);
        this._dock.add_child(right);
    }
    _buildMenu() {
        this._startMenu = new St.BoxLayout({
            style_class: 'obos-menu', vertical: true, reactive: true, width: 630,
            track_hover: true, visible: false, opacity: 0,
        });
        this._blur(this._startMenu, 30);
        const head = new St.BoxLayout({style_class: 'obos-menu-head', vertical: true});
        const eyebrow = new St.BoxLayout({style_class: 'obos-menu-top'});
        eyebrow.add_child(this._text('✦  ONEBOOKOS', 'obos-menu-brand'));
        const version = this._text('0.2  /  GNOME', 'obos-menu-version');
        eyebrow.add_child(version);
        head.add_child(eyebrow);
        head.add_child(this._text('Good to see you.', 'obos-menu-title'));
        head.add_child(this._text('Everything you need, beautifully organized.', 'obos-menu-subtitle'));
        this._search = new St.Entry({
            style_class: 'obos-search', hint_text: 'Search applications…',
            can_focus: true, track_hover: true,
        });
        this._search.set_primary_icon(this._icon('search-symbolic', 18));
        this._connect(this._search.get_clutter_text(), 'text-changed', () => {
            this._searchTerm = this._search.get_text().trim().toLowerCase();
            this._refreshApps();
        });
        head.add_child(this._search);
        this._startMenu.add_child(head);

        const pinnedHeader = new St.BoxLayout({style_class: 'obos-section-header'});
        pinnedHeader.add_child(this._text('Favorites', 'obos-section-title'));
        pinnedHeader.add_child(this._text('PINNED', 'obos-hint'));
        this._startMenu.add_child(pinnedHeader);

        this._pinned = new St.BoxLayout({style_class: 'obos-pinned'});
        for (const [name, id, icon] of CORE.slice(0,6)) {
            const tile = new St.BoxLayout({style_class: 'obos-pinned-tile', vertical: true});
            tile.add_child(this._icon(icon, 42));
            tile.add_child(this._text(name, 'obos-app-name'));
            const btn = new St.Button({style_class: 'obos-tile-button', child: tile, can_focus: true, accessible_name: name});
            this._connect(btn, 'clicked', () => this._launch(id));
            this._pinned.add_child(btn);
        }
        this._startMenu.add_child(this._pinned);

        const categoriesTitle = new St.BoxLayout({style_class: 'obos-section-header'});
        categoriesTitle.add_child(this._text('Applications', 'obos-section-title'));
        categoriesTitle.add_child(this._text('DISCOVER', 'obos-hint'));
        this._startMenu.add_child(categoriesTitle);
        this._categoryRow = new St.BoxLayout({style_class: 'obos-categories'});
        for (const category of CATEGORIES) {
            const button = new St.Button({label: category, style_class: 'obos-category', can_focus: true});
            this._connect(button, 'clicked', () => {
                this._category = category;
                this._refreshApps();
            });
            this._categoryRow.add_child(button);
        }
        this._startMenu.add_child(this._categoryRow);
        const scroll = new St.ScrollView({style_class: 'obos-app-scroll', overlay_scrollbars: true});
        scroll.set_policy(St.PolicyType.NEVER, St.PolicyType.AUTOMATIC);
        this._appList = new St.BoxLayout({vertical: true, style_class: 'obos-app-list'});
        scroll.add_actor(this._appList);
        this._startMenu.add_child(scroll);
        const footer = new St.BoxLayout({style_class: 'obos-menu-footer'});
        footer.add_child(this._text('ONEBOOKOS  •  YOUR SPACE, YOUR FLOW', 'obos-footer-label'));
        footer.add_child(this._button('settings', 'Settings', () => this._launch('org.gnome.Settings.desktop')));
        footer.add_child(this._button('power', 'Power menu', () => {
            this._hideMenu();
            Main.panel.statusArea.quickSettings?.menu.toggle();
        }));
        this._startMenu.add_child(footer);
        this._refreshApps();
    }
    _refreshApps() {
        if (!this._appList) return;
        this._appList.destroy_all_children();
        this._categoryRow.get_children().forEach((item,i) => {
            item.set_style_class_name(i === CATEGORIES.indexOf(this._category) ? 'obos-category obos-category-selected' : 'obos-category');
        });
        const apps = this._allApps().filter(app =>
            (this._category === 'All' || app.category === this._category) &&
            (!this._searchTerm || (app.name + ' ' + app.id).toLowerCase().includes(this._searchTerm)));
        if (!apps.length) {
            this._appList.add_child(this._text('No matching applications. Try another search.', 'obos-empty'));
            return;
        }
        // Show up to 50 apps initially to avoid overwhelming an Alpha live system.
        for (let i = 0; i < Math.min(apps.length, 50); i += 4) {
            const row = new St.BoxLayout({style_class: 'obos-app-row'});
            for (const app of apps.slice(i, i + 4)) {
                const tile = new St.BoxLayout({style_class: 'obos-grid-tile', vertical: true});
                if (app.icon) tile.add_child(this._icon(app.icon, 37));
                else tile.add_child(new St.Icon({
                    gicon: app.appInfo.get_icon() ?? new Gio.ThemedIcon({name: 'application-x-executable'}),
                    icon_size: 37,
                }));
                const name = app.name.length > 17 ? app.name.substring(0,15) + '…' : app.name;
                tile.add_child(this._text(name, 'obos-grid-name'));
                const button = new St.Button({style_class: 'obos-app-tile', child: tile, can_focus: true, accessible_name: app.name});
                this._connect(button, 'clicked', () => this._launch(app.id));
                row.add_child(button);
            }
            this._appList.add_child(row);
        }
    }
    _toggleMenu() {
        if (this._menuOpen) { this._hideMenu(); return; }
        this._menuOpen = true;
        this._startMenu.show();
        this._startMenu.opacity = 0;
        this._relayout();
        this._startMenu.ease({opacity: 255, duration: ANIMATION, mode: Clutter.AnimationMode.EASE_OUT_QUAD});
        this._startButton.add_style_class_name('obos-start-active');
        this._search.grab_key_focus();
    }
    _hideMenu() {
        if (!this._menuOpen) return;
        this._menuOpen = false;
        this._startButton.remove_style_class_name('obos-start-active');
        this._startMenu.remove_all_transitions();
        this._startMenu.ease({
            opacity: 0, duration: 125, mode: Clutter.AnimationMode.EASE_OUT_QUAD,
            onComplete: () => { if (!this._menuOpen && this._startMenu) this._startMenu.hide(); },
        });
    }
    _buildNotch() {
        this._notch = new St.BoxLayout({
            style_class: 'obos-notch-shell', vertical: true, reactive: true, track_hover: true,
        });
        const compact = new St.BoxLayout({style_class: 'obos-notch-compact'});
        compact.add_child(this._icon('onebook', 18));
        compact.add_child(this._text('OneBookOS', 'obos-notch-title'));
        compact.add_child(this._text('●', 'obos-notch-hint'));
        this._compact = compact;
        this._notch.add_child(compact);
        const expanded = new St.BoxLayout({style_class: 'obos-notch-expanded', vertical: true});
        expanded.add_child(this._text('OneBook Hub', 'obos-notch-heading'));
        expanded.add_child(this._text('Quickly get back to what matters.', 'obos-notch-caption'));
        const shortcuts = new St.BoxLayout({style_class: 'obos-notch-shortcuts'});
        for (const [icon, name, id] of [
            ['settings','Settings','org.gnome.Settings.desktop'],
            ['files','Files','org.gnome.Nautilus.desktop'],
            ['monitor','System monitor','org.gnome.SystemMonitor.desktop'],
        ]) {
            const btn = this._button(icon, name, () => this._launch(id), 'obos-hub-action', 28);
            shortcuts.add_child(btn);
        }
        expanded.add_child(shortcuts);
        expanded.add_child(this._text('GNOME 46  ·  Ubuntu 24.04  ·  OneBookOS 0.2', 'obos-notch-caption'));
        this._expandedBody = expanded;
        this._notch.add_child(expanded);
        expanded.hide();
        this._connect(this._notch, 'notify::hover', () => {
            const show = this._notch.hover;
            if (show === this._expanded) return;
            this._expanded = show;
            this._compact.visible = !show;
            this._expandedBody.visible = show;
            this._relayout();
        });
    }
    _clockTick() {
        const now = GLib.DateTime.new_now_local();
        this._timeLabel.set_text(now.format('%H:%M'));
        this._dateLabel.set_text(now.format('%a, %d %b'));
        return GLib.SOURCE_CONTINUE;
    }
    _relayout() {
        const m = Main.layoutManager.primaryMonitor;
        if (!m || !this._dock) return;
        const dockW = this._dock.width || 450;
        const dockH = this._dock.height || 64;
        this._dock.set_position(Math.round(m.x + (m.width - dockW) / 2),
            Math.round(m.y + m.height - dockH - 13));
        const notchW = this._notch.width || 160;
        this._notch.set_position(Math.round(m.x + (m.width - notchW) / 2), m.y);
        const menuW = Math.min(this._startMenu.width || 630, m.width - 24);
        this._startMenu.set_width(menuW);
        const menuH = this._startMenu.height || 610;
        this._startMenu.set_position(Math.round(m.x + (m.width - menuW) / 2),
            Math.max(m.y + 20, Math.round(m.y + m.height - dockH - menuH - 31)));
    }
    disable() {
        for (const timer of this._timers ?? []) GLib.Source.remove(timer);
        for (const [obj,id] of this._signals ?? []) {
            try { obj.disconnect(id); } catch {}
        }
        this._timers = []; this._signals = [];
        this._dock?.destroy(); this._startMenu?.destroy(); this._notch?.destroy();
        this._dock = null; this._startMenu = null; this._notch = null;
        Main.panel.show();
        try { Gio.File.new_for_path('/tmp/obos-gnome-extension-ready').delete(null); } catch {}
    }
}

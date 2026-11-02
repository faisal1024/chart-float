import Cocoa
import WebKit

// ChartFloat: a small always-on-top browser window for keeping a chart in view.

let defaults = UserDefaults.standard
let kURL = "chartURL"
let kOpacity = "opacity"
let kPinned = "pinned"
let kToolbarHidden = "toolbarHidden"

final class FloatWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, NSTextFieldDelegate {
    var window: FloatWindow!
    var webView: WKWebView!
    var toolbar: NSView!
    var urlField: NSTextField!
    var opacitySlider: NSSlider!
    var pinButton: NSButton!
    var statusItem: NSStatusItem!
    var clickThrough = false
    var toolbarHeightConstraint: NSLayoutConstraint!

    var pinned: Bool {
        get { defaults.object(forKey: kPinned) as? Bool ?? true }
        set { defaults.set(newValue, forKey: kPinned); applyPin() }
    }

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildMenu()
        buildWindow()
        buildStatusItem()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: Window

    func buildWindow() {
        let frame = NSRect(x: 0, y: 0, width: 520, height: 360)
        window = FloatWindow(contentRect: frame,
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
        window.title = "ChartFloat"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.minSize = NSSize(width: 200, height: 120)
        window.setFrameAutosaveName("ChartFloatMain")
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .managed]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        // Toolbar row
        toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.wantsLayer = true
        content.addSubview(toolbar)

        let back = NSButton(title: "‹", target: self, action: #selector(goBack))
        back.bezelStyle = .texturedRounded
        let reload = NSButton(title: "↻", target: self, action: #selector(reload))
        reload.bezelStyle = .texturedRounded

        urlField = NSTextField()
        urlField.placeholderString = "Paste chart URL and press Return"
        urlField.delegate = self
        urlField.font = NSFont.systemFont(ofSize: 12)
        urlField.lineBreakMode = .byTruncatingTail
        urlField.cell?.usesSingleLineMode = true
        urlField.cell?.isScrollable = true

        opacitySlider = NSSlider(value: defaults.object(forKey: kOpacity) as? Double ?? 1.0,
                                 minValue: 0.25, maxValue: 1.0,
                                 target: self, action: #selector(opacityChanged))
        opacitySlider.toolTip = "Window opacity"
        opacitySlider.controlSize = .small

        pinButton = NSButton(title: "📌", target: self, action: #selector(togglePin))
        pinButton.bezelStyle = .texturedRounded
        pinButton.setButtonType(.pushOnPushOff)
        pinButton.toolTip = "Always on top"

        let stack = NSStackView(views: [back, reload, urlField, opacitySlider, pinButton])
        stack.orientation = .horizontal
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 74, bottom: 0, right: 8) // room for traffic lights
        stack.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(stack)

        urlField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        urlField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        opacitySlider.widthAnchor.constraint(equalToConstant: 70).isActive = true

        // Web view
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
        content.addSubview(webView)

        toolbarHeightConstraint = toolbar.heightAnchor.constraint(equalToConstant: 38)
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: content.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            toolbarHeightConstraint,
            stack.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])

        if !window.setFrameUsingName("ChartFloatMain") {
            // First launch: bottom-right corner of the main screen
            if let screen = NSScreen.main {
                let v = screen.visibleFrame
                window.setFrameOrigin(NSPoint(x: v.maxX - frame.width - 20, y: v.minY + 20))
            }
        }

        applyPin()
        window.alphaValue = CGFloat(opacitySlider.doubleValue)
        setToolbarHidden(defaults.bool(forKey: kToolbarHidden))

        let saved = defaults.string(forKey: kURL) ?? "https://www.tradingview.com/chart/"
        urlField.stringValue = saved
        load(saved)
        window.makeKeyAndOrderFront(nil)
    }

    func applyPin() {
        window.level = pinned ? .floating : .normal
        pinButton?.state = pinned ? .on : .off
        pinButton?.contentTintColor = pinned ? .controlAccentColor : nil
        statusItem?.menu?.item(withTag: 1)?.state = pinned ? .on : .off
    }

    func setToolbarHidden(_ hidden: Bool) {
        defaults.set(hidden, forKey: kToolbarHidden)
        toolbar.isHidden = hidden
        toolbarHeightConstraint.constant = hidden ? 0 : 38
        // Keep the traffic lights reachable even when the bar is hidden.
        for b: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(b)?.isHidden = false
        }
        statusItem?.menu?.item(withTag: 3)?.state = hidden ? .on : .off
    }

    func setClickThrough(_ on: Bool) {
        clickThrough = on
        window.ignoresMouseEvents = on
        statusItem?.menu?.item(withTag: 2)?.state = on ? .on : .off
        statusItem?.button?.title = on ? "📈👻" : "📈"
    }

    func load(_ text: String) {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        if !s.contains("://") { s = "https://" + s }
        guard let url = URL(string: s) else { return }
        defaults.set(s, forKey: kURL)
        webView.load(URLRequest(url: url))
    }

    // MARK: Actions

    @objc func goBack() { webView.goBack() }
    @objc func reload() { webView.reload() }
    @objc func togglePin() { pinned.toggle() }
    @objc func toggleClickThrough() { setClickThrough(!clickThrough) }
    @objc func toggleToolbar() { setToolbarHidden(!toolbar.isHidden) }
    @objc func focusURL() {
        if toolbar.isHidden { setToolbarHidden(false) }
        window.makeFirstResponder(urlField)
    }
    @objc func opacityChanged() {
        window.alphaValue = CGFloat(opacitySlider.doubleValue)
        defaults.set(opacitySlider.doubleValue, forKey: kOpacity)
    }
    @objc func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField, field == urlField else { return }
        if let move = obj.userInfo?["NSTextMovement"] as? Int, move == NSReturnTextMovement {
            load(urlField.stringValue)
            window.makeFirstResponder(webView)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let u = webView.url?.absoluteString, window.firstResponder != urlField?.currentEditor() {
            urlField.stringValue = u
            defaults.set(u, forKey: kURL)
        }
    }

    // MARK: Menus

    func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "📈"
        let m = NSMenu()
        m.addItem(withTitle: "Show ChartFloat", action: #selector(showWindow), keyEquivalent: "")
        m.addItem(.separator())
        let pin = m.addItem(withTitle: "Always on Top", action: #selector(togglePin), keyEquivalent: "")
        pin.tag = 1
        let ct = m.addItem(withTitle: "Click-Through (ignore mouse)", action: #selector(toggleClickThrough), keyEquivalent: "")
        ct.tag = 2
        let tb = m.addItem(withTitle: "Hide Toolbar", action: #selector(toggleToolbar), keyEquivalent: "")
        tb.tag = 3
        m.addItem(.separator())
        m.addItem(withTitle: "Quit ChartFloat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = m
        applyPin()
    }

    func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let app = NSMenu()
        app.addItem(withTitle: "Hide ChartFloat", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Quit ChartFloat", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = app

        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "View")
        view.addItem(withTitle: "Open URL…", action: #selector(focusURL), keyEquivalent: "l")
        view.addItem(withTitle: "Reload", action: #selector(reload), keyEquivalent: "r")
        view.addItem(withTitle: "Back", action: #selector(goBack), keyEquivalent: "[")
        view.addItem(.separator())
        view.addItem(withTitle: "Always on Top", action: #selector(togglePin), keyEquivalent: "p")
        view.addItem(withTitle: "Click-Through", action: #selector(toggleClickThrough), keyEquivalent: "t")
        view.addItem(withTitle: "Toggle Toolbar", action: #selector(toggleToolbar), keyEquivalent: "b")
        viewItem.submenu = view

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

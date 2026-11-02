# ChartFloat

A tiny always-on-top browser window for macOS. Keep a market chart (TradingView, your broker, anything) floating in a corner above every other app, on every Space, including over full-screen apps.

No dependencies, no Xcode project. One Swift file, built with `swiftc`.

## Build and run

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/faisal1024/chart-float.git
cd chart-float
./build.sh
open ChartFloat.app
```

Copy `ChartFloat.app` to `/Applications` if you want it in Launchpad.

The app is ad-hoc signed, so on first launch macOS may say it can't verify the developer. Right-click the app, choose Open, then Open again. You only have to do this once.

## Mirror a Chrome tab (picture-in-picture for any window)

Want to watch a tab you already have open in Chrome, logged in and all? Mirror it:

1. In Chrome, right-click the tab and choose **Move Tab to New Window** so the chart has its own window.
2. In ChartFloat click **Mirror** (or Cmd+M, or the 📈 menu bar item), and pick that Chrome window in the system picker.
3. The floating panel now shows a live feed of that window, even when Chrome is buried behind other apps or on another Space. Click **Stop** to go back to the built-in browser.

The feed is view-only: clicks land on ChartFloat, not on Chrome. Minimizing the Chrome window stops the feed, so leave it open behind your other windows. The first time, macOS asks you to allow ChartFloat to share the window.

## Using it

- Paste a URL in the toolbar and press Return. Logins persist between launches.
- Drag the window anywhere, resize it as small as you like (down to 200×120).
- **📌 / Cmd+P** toggles always-on-top.
- **Opacity slider** fades the window.
- **Cmd+B** hides the toolbar for a chart-only window. Cmd+L brings it back and focuses the URL field.
- **Cmd+T** or the 📈 menu bar item toggles click-through: the window ignores the mouse so you can work underneath it. Turn it back off from the 📈 menu bar item.
- Cmd+R reloads, Cmd+[ goes back.

URL, size, position, opacity and settings are remembered.

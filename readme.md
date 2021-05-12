# Touch Bar Simulator [<img src="Stuff/AppIcon-readme.png" width="160" align="right">](https://github.com/sindresorhus/touch-bar-simulator/releases/latest)

> Use the Touch Bar on any Mac

Launch the Touch Bar simulator from anywhere without needing to have Xcode installed, whereas Apple requires you to launch it from inside Xcode. It also comes with a handy transparency slider, a screenshot button, and a menu bar icon and system service to toggle the Touch Bar with a click or keyboard shortcut.

**Important:** There is a [problem](https://github.com/sindresorhus/touch-bar-simulator/issues/61) with using this on Catalina. If you launch Xcode or relaunch Touch Bar Simulator, you will no longer be able to interact (click) with the Touch Bar view until you restart your computer. Which is not ideal. So if you want to use this reliably; don't launch Xcode and don't restart this app.

<img src="screenshot-menu-bar.png" width="277" align="left">

Clicking the menu bar icon toggles the Touch Bar window.

Right-clicking or option-clicking the menu bar icon displays a menu with options to dock the window to the top or bottom of the screen, make it show on all desktops at once, access toolbar features in docked mode, automatically show and hide the Touch Bar, or quit the app.

<img src="screenshot.png" width="1129">

## Getting started

#### [Download the latest release](https://sindresorhus.com/touch-bar-simulator)

Or install it with [Homebrew-Cask](https://caskroom.github.io):

```
$ brew install touch-bar-simulator
```

*Requires macOS 11 or later.*

## Screenshot

You can capture a screenshot of the Touch Bar by either:

1. Clicking the screenshot button in the Touch Bar window or options menu which saves it to `~/Desktop`.
2. Pressing <kbd>⇧⌘6</kbd> which saves it to `~/Desktop`.
3. Pressing <kbd>⌃⇧⌘6</kbd> which saves it to the clipboard.

## FAQ

### Clicking in the simulator window is not working

Go to “System Preferences › Security & Privacy › Accessibility“ and ensure “Touch Bar Simulator.app“ is checked. If it's already checked, try unchecking and checking it again.

### Why is this not on the App Store?

Apple would never allow it as it uses private APIs.

### Can I set a keyboard shortcut?

Right-click or option-click the menu bar icon, select “Keyboard Shortcuts…”, and add your shortcut.

### Can I contribute localizations?

No, we're not interested in localizing the app.

### How does this work?

~~In short, it exposes the Touch Bar simulator from inside Xcode as a standalone app with added features. I [class-dumped](https://github.com/nygard/class-dump) a private Xcode framework and used that to expose a private class to get a reference to the Touch Bar window controller. I then launch that window and add a screenshot button to it. I've bundled the required private frameworks to make it work without Xcode. That's why the binary is so big.~~

Xcode 10 moved the required private symbols needed to trigger the Touch Bar simulator into the main IDEKit framework, which has a lot of dependencies on its own. I managed to get it working by including all those frameworks, but the app ended up being 700 MB... I then went back to the drawing board. I discovered a way to communicate with the Touch Bar simulator directly. The result of this is a faster and more stable app.

## Build

```
./build
```

## Other apps

- [Gifski](https://github.com/sindresorhus/Gifski) - Convert videos to high-quality GIFs on your Mac
- [More apps…](https://sindresorhus.com/apps)

## Links

- [Product Hunt submission](https://www.producthunt.com/posts/touch-bar-simulator)

## Maintainers

- [Sindre Sorhus](https://github.com/sindresorhus)
- [@ThatsJustCheesy](https://github.com/ThatsJustCheesy)

import Cocoa

/// A fullscreen overlay window that dims all screens and shows a centered dialog.
/// User must interact with the dialog to dismiss — cannot click through.
class OverlayWindow {
  static var shared = OverlayWindow()

  private var windows: [NSWindow] = []
  private var onResponse: ((String) -> Void)?

  /// Show an overlay on all screens with a title, message, and action buttons.
  func show(title: String, message: String, actions: [String], onResponse: @escaping (String) -> Void) {
    dismiss() // Clear any existing overlay

    self.onResponse = onResponse

    // Create an overlay window for each screen
    for screen in NSScreen.screens {
      let window = NSWindow(
        contentRect: screen.frame,
        styleMask: .borderless,
        backing: .buffered,
        defer: false
      )
      window.level = .screenSaver
      window.backgroundColor = NSColor.black.withAlphaComponent(0.6)
      window.isOpaque = false
      window.hasShadow = false
      window.ignoresMouseEvents = false
      window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

      // Only the main screen gets the dialog
      if screen == NSScreen.main {
        let contentView = OverlayContentView(
          title: title,
          message: message,
          actions: actions,
          onAction: { [weak self] action in
            self?.handleAction(action)
          }
        )
        window.contentView = contentView
      }

      window.orderFrontRegardless()
      windows.append(window)
    }

    // Bring to front
    NSApp.activate(ignoringOtherApps: true)
  }

  private func handleAction(_ action: String) {
    let callback = onResponse
    dismiss()
    callback?(action)
  }

  func dismiss() {
    for window in windows {
      window.orderOut(nil)
    }
    windows.removeAll()
    onResponse = nil
  }
}

/// The content view for the overlay dialog.
class OverlayContentView: NSView {
  let titleText: String
  let messageText: String
  let actions: [String]
  let onAction: (String) -> Void

  init(title: String, message: String, actions: [String], onAction: @escaping (String) -> Void) {
    self.titleText = title
    self.messageText = message
    self.actions = actions
    self.onAction = onAction
    super.init(frame: .zero)
    setupUI()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupUI() {
    wantsLayer = true

    // Center dialog container
    let dialog = NSView()
    dialog.wantsLayer = true
    dialog.layer?.backgroundColor = NSColor(white: 0.15, alpha: 0.95).cgColor
    dialog.layer?.cornerRadius = 16
    dialog.translatesAutoresizingMaskIntoConstraints = false
    addSubview(dialog)

    NSLayoutConstraint.activate([
      dialog.centerXAnchor.constraint(equalTo: centerXAnchor),
      dialog.centerYAnchor.constraint(equalTo: centerYAnchor),
      dialog.widthAnchor.constraint(equalToConstant: 420),
    ])

    // Icon
    let icon = NSImageView()
    icon.image = NSImage(systemSymbolName: "clock.badge.exclamationmark", accessibilityDescription: "Timer alert")
    icon.symbolConfiguration = .init(pointSize: 36, weight: .light)
    icon.contentTintColor = .white
    icon.translatesAutoresizingMaskIntoConstraints = false
    dialog.addSubview(icon)

    // Title
    let titleLabel = NSTextField(labelWithString: titleText)
    titleLabel.font = NSFont.systemFont(ofSize: 22, weight: .semibold)
    titleLabel.textColor = .white
    titleLabel.alignment = .center
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    dialog.addSubview(titleLabel)

    // Message
    let messageLabel = NSTextField(wrappingLabelWithString: messageText)
    messageLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
    messageLabel.textColor = NSColor(white: 0.75, alpha: 1.0)
    messageLabel.alignment = .center
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    dialog.addSubview(messageLabel)

    // Buttons stack
    let buttonStack = NSStackView()
    buttonStack.orientation = .vertical
    buttonStack.spacing = 8
    buttonStack.translatesAutoresizingMaskIntoConstraints = false
    dialog.addSubview(buttonStack)

    for (index, actionTitle) in actions.enumerated() {
      let button = NSButton(title: actionTitle, target: self, action: #selector(buttonClicked(_:)))
      button.tag = index
      button.bezelStyle = .rounded
      button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
      button.translatesAutoresizingMaskIntoConstraints = false

      // First button is primary (accent color)
      if index == 0 {
        button.keyEquivalent = "\r"
        button.contentTintColor = .white
        button.bezelColor = NSColor(red: 0.36, green: 0.49, blue: 0.98, alpha: 1.0) // accent blue
      }

      buttonStack.addArrangedSubview(button)
      button.widthAnchor.constraint(equalToConstant: 280).isActive = true
    }

    NSLayoutConstraint.activate([
      icon.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
      icon.topAnchor.constraint(equalTo: dialog.topAnchor, constant: 28),

      titleLabel.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
      titleLabel.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 16),
      titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dialog.leadingAnchor, constant: 24),

      messageLabel.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
      messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      messageLabel.leadingAnchor.constraint(equalTo: dialog.leadingAnchor, constant: 24),
      messageLabel.trailingAnchor.constraint(equalTo: dialog.trailingAnchor, constant: -24),

      buttonStack.centerXAnchor.constraint(equalTo: dialog.centerXAnchor),
      buttonStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
      buttonStack.bottomAnchor.constraint(equalTo: dialog.bottomAnchor, constant: -28),
    ])
  }

  @objc private func buttonClicked(_ sender: NSButton) {
    if sender.tag < actions.count {
      onAction(actions[sender.tag])
    }
  }

  // Block all mouse events from passing through
  override func mouseDown(with event: NSEvent) {}
  override func mouseUp(with event: NSEvent) {}
  override func rightMouseDown(with event: NSEvent) {}
  override func rightMouseUp(with event: NSEvent) {}
}

import UIKit

final class ChatViewController: UIViewController {
    private let viewModel: ChatViewModel

    private let gradientLayer = CAGradientLayer()

    private let headerView = UIView()
    private let menuButton = UIButton(type: .system)
    private let rightHeaderSpacer = UIView()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let metricsLabel = UILabel()
    private let inputContainer = UIView()
    private let addButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let sendActivityIndicator = UIActivityIndicatorView(style: .medium)

    private let dimView = UIView()
    private let sidePanel = UIView()
    private let sessionsTableView = UITableView(frame: .zero, style: .plain)
    private let newChatButton = UIButton(type: .system)
    private var sidePanelLeadingConstraint: NSLayoutConstraint?
    private var isSidePanelOpen = false
    private var shouldAutoScrollToBottom = true
    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideInput))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureViews()
        bindViewModel()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        Task { await viewModel.refreshActiveModel() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func configureBackground() {
        view.backgroundColor = UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 0.04, green: 0.08, blue: 0.20, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.03, blue: 0.10, alpha: 1).cgColor,
            UIColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1).cgColor,
        ]
        gradientLayer.locations = [0, 0.45, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureViews() {
        navigationItem.title = nil
        title = nil

        configureHeader()
        configureMessagesTable()
        configureInput()
        configureSidebar()
        configureLayout()
        configureKeyboardDismissGesture()
    }

    private func configureKeyboardDismissGesture() {
        view.addGestureRecognizer(dismissKeyboardTapGesture)
    }

    private func configureHeader() {
        menuButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        menuButton.tintColor = UIColor.white.withAlphaComponent(0.9)
        menuButton.addTarget(self, action: #selector(didTapMenu), for: .touchUpInside)

        titleLabel.text = viewModel.activeModelDisplayName
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.minimumScaleFactor = 0.85
        titleLabel.adjustsFontSizeToFitWidth = true

        statusLabel.text = "Online"
        statusLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)
        statusLabel.textAlignment = .center

        headerView.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        rightHeaderSpacer.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        headerView.addSubviews(menuButton, rightHeaderSpacer, titleLabel, statusLabel)
    }

    private func configureMessagesTable() {
        tableView.register(MessageTableViewCell.self, forCellReuseIdentifier: MessageTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .interactive
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 12, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureInput() {
        metricsLabel.text = "• Local • \(viewModel.activeModelDisplayName)"
        metricsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        metricsLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        metricsLabel.textAlignment = .center
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 0.95)
        inputContainer.layer.cornerRadius = 20
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        addButton.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        addButton.layer.cornerRadius = 16
        addButton.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = "Message Local AI..."
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.textColor = .white
        textField.tintColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.returnKeyType = .send
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = UIColor(red: 0.10, green: 0.52, blue: 1.0, alpha: 1)
        sendButton.layer.cornerRadius = 24
        sendButton.layer.shadowColor = UIColor(red: 0.10, green: 0.52, blue: 1.0, alpha: 1).cgColor
        sendButton.layer.shadowOpacity = 0.45
        sendButton.layer.shadowRadius = 10
        sendButton.layer.shadowOffset = .zero
        sendButton.addTarget(self, action: #selector(didTapSend), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendActivityIndicator.color = .white
        sendActivityIndicator.hidesWhenStopped = true
        sendActivityIndicator.translatesAutoresizingMaskIntoConstraints = false

        inputContainer.addSubviews(addButton, textField, sendButton)
        sendButton.addSubview(sendActivityIndicator)
    }

    private func configureSidebar() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        dimView.alpha = 0
        dimView.isHidden = true
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeSidePanel)))

        sidePanel.backgroundColor = UIColor(red: 0.03, green: 0.06, blue: 0.14, alpha: 0.98)
        sidePanel.layer.borderWidth = 1
        sidePanel.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        sidePanel.layer.shadowColor = UIColor.black.cgColor
        sidePanel.layer.shadowOpacity = 0.35
        sidePanel.layer.shadowRadius = 10
        sidePanel.layer.shadowOffset = CGSize(width: 4, height: 0)
        sidePanel.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = UILabel()
        headerLabel.text = "Conversations"
        headerLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        headerLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        newChatButton.setTitle("New Chat", for: .normal)
        newChatButton.setTitleColor(.white, for: .normal)
        newChatButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        newChatButton.backgroundColor = UIColor(red: 0.10, green: 0.52, blue: 1.0, alpha: 0.92)
        newChatButton.layer.cornerRadius = 12
        newChatButton.addTarget(self, action: #selector(didTapNewChat), for: .touchUpInside)
        newChatButton.translatesAutoresizingMaskIntoConstraints = false

        sessionsTableView.dataSource = self
        sessionsTableView.delegate = self
        sessionsTableView.backgroundColor = .clear
        sessionsTableView.separatorStyle = .none
        sessionsTableView.showsVerticalScrollIndicator = false
        sessionsTableView.translatesAutoresizingMaskIntoConstraints = false

        sidePanel.addSubviews(headerLabel, newChatButton, sessionsTableView)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: sidePanel.safeAreaLayoutGuide.topAnchor, constant: 14),
            headerLabel.leadingAnchor.constraint(equalTo: sidePanel.leadingAnchor, constant: 14),
            headerLabel.trailingAnchor.constraint(equalTo: sidePanel.trailingAnchor, constant: -14),

            newChatButton.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 10),
            newChatButton.leadingAnchor.constraint(equalTo: sidePanel.leadingAnchor, constant: 14),
            newChatButton.trailingAnchor.constraint(equalTo: sidePanel.trailingAnchor, constant: -14),
            newChatButton.heightAnchor.constraint(equalToConstant: 42),

            sessionsTableView.topAnchor.constraint(equalTo: newChatButton.bottomAnchor, constant: 12),
            sessionsTableView.leadingAnchor.constraint(equalTo: sidePanel.leadingAnchor),
            sessionsTableView.trailingAnchor.constraint(equalTo: sidePanel.trailingAnchor),
            sessionsTableView.bottomAnchor.constraint(equalTo: sidePanel.bottomAnchor),
        ])
    }

    private func configureLayout() {
        view.addSubviews(headerView, tableView, metricsLabel, inputContainer, dimView, sidePanel)

        let panelWidth: CGFloat = min(320, view.bounds.width * 0.78)
        sidePanelLeadingConstraint = sidePanel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -panelWidth)
        sidePanelLeadingConstraint?.isActive = true

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 50),

            menuButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            menuButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            menuButton.widthAnchor.constraint(equalToConstant: 38),
            menuButton.heightAnchor.constraint(equalToConstant: 38),

            rightHeaderSpacer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            rightHeaderSpacer.centerYAnchor.constraint(equalTo: menuButton.centerYAnchor),
            rightHeaderSpacer.widthAnchor.constraint(equalTo: menuButton.widthAnchor),
            rightHeaderSpacer.heightAnchor.constraint(equalTo: menuButton.heightAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: menuButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightHeaderSpacer.leadingAnchor, constant: -8),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 16),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10),
            inputContainer.heightAnchor.constraint(equalToConstant: 58),

            metricsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            metricsLabel.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -10),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 2),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: metricsLabel.topAnchor, constant: -8),

            addButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
            addButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
            sendActivityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            sendActivityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            textField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 32),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidePanel.widthAnchor.constraint(equalToConstant: panelWidth),
        ])
    }

    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            guard self.shouldAutoScrollToBottom else { return }
            self.scrollToBottom(animated: false)
        }

        viewModel.onModelUpdated = { [weak self] modelName in
            self?.metricsLabel.text = "• Local • \(modelName)"
            self?.titleLabel.text = modelName
        }

        viewModel.onSessionsUpdated = { [weak self] _ in
            self?.sessionsTableView.reloadData()
        }

        viewModel.onActiveSessionUpdated = { [weak self] _ in
            self?.sessionsTableView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }

        viewModel.onGenerationStateUpdated = { [weak self] generating in
            self?.applyGenerationState(generating)
        }
    }

    @objc
    private func didTapSend() {
        guard !viewModel.isGenerating else { return }
        let text = textField.text ?? ""
        textField.text = nil
        shouldAutoScrollToBottom = true
        viewModel.sendMessage(text)
    }

    @objc
    private func didTapMenu() {
        isSidePanelOpen ? closeSidePanel() : openSidePanel()
    }

    @objc
    private func didTapNewChat() {
        viewModel.startNewChat()
        closeSidePanel()
    }

    @objc
    private func didTapOutsideInput() {
        view.endEditing(true)
    }

    @objc
    private func closeSidePanel() {
        guard isSidePanelOpen else { return }
        isSidePanelOpen = false
        let panelWidth = sidePanel.bounds.width > 0 ? sidePanel.bounds.width : min(320, view.bounds.width * 0.78)
        sidePanelLeadingConstraint?.constant = -panelWidth
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
            self.dimView.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dimView.isHidden = true
        }
    }

    private func openSidePanel() {
        guard !isSidePanelOpen else { return }
        isSidePanelOpen = true
        dimView.isHidden = false
        sidePanelLeadingConstraint?.constant = 0
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
            self.dimView.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === sessionsTableView {
            return viewModel.sessions.count
        }
        return viewModel.messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === sessionsTableView {
            let reuseID = "SessionCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseID) ??
                UITableViewCell(style: .subtitle, reuseIdentifier: reuseID)
            let session = viewModel.sessions[indexPath.row]
            cell.backgroundColor = .clear
            cell.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            cell.textLabel?.textColor = .white
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            cell.detailTextLabel?.textColor = UIColor.white.withAlphaComponent(0.58)
            cell.textLabel?.text = session.title
            cell.imageView?.image = session.isPinned ? UIImage(systemName: "pin.fill") : nil
            cell.imageView?.tintColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1)

            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            cell.detailTextLabel?.text = formatter.localizedString(for: session.createdAt, relativeTo: Date())

            let selected = session.id == viewModel.activeSessionID
            cell.contentView.backgroundColor = selected
                ? UIColor(red: 0.10, green: 0.30, blue: 0.70, alpha: 0.35)
                : .clear
            cell.contentView.layer.cornerRadius = 10
            cell.selectionStyle = .none
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseID, for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(message: viewModel.messages[indexPath.row], modelName: viewModel.activeModelDisplayName)
        return cell
    }
}

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView === sessionsTableView else { return }
        let session = viewModel.sessions[indexPath.row]
        viewModel.selectSession(session.id)
        closeSidePanel()
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard tableView === sessionsTableView else { return nil }
        let session = viewModel.sessions[indexPath.row]
        return UIContextMenuConfiguration(identifier: session.id as NSUUID, previewProvider: nil) { [weak self] _ in
            guard let self else { return nil }

            let pinTitle = session.isPinned ? "Unpin" : "Pin"
            let pinIcon = session.isPinned ? "pin.slash" : "pin"
            let pinAction = UIAction(title: pinTitle, image: UIImage(systemName: pinIcon)) { _ in
                self.viewModel.togglePinSession(session.id)
            }

            let renameAction = UIAction(title: "Rename", image: UIImage(systemName: "pencil")) { _ in
                self.presentRenameAlert(for: session)
            }

            let removeAction = UIAction(title: "Remove", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                self.viewModel.deleteSession(session.id)
            }

            return UIMenu(title: "", children: [pinAction, renameAction, removeAction])
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        shouldAutoScrollToBottom = isNearBottom()
    }
}

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        didTapSend()
        return true
    }
}

extension ChatViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === dismissKeyboardTapGesture else { return true }

        // Keep interaction inside the composer untouched.
        if let touchedView = touch.view, touchedView.isDescendant(of: inputContainer) {
            return false
        }
        return true
    }
}

private extension ChatViewController {
    func applyGenerationState(_ generating: Bool) {
        sendButton.isEnabled = !generating
        addButton.isEnabled = !generating
        if generating {
            sendButton.setImage(nil, for: .normal)
            sendActivityIndicator.startAnimating()
        } else {
            sendActivityIndicator.stopAnimating()
            sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        }
    }

    func presentRenameAlert(for session: ChatSession) {
        let alert = UIAlertController(title: "Rename Chat", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = session.title
            textField.placeholder = "Chat title"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let newTitle = alert.textFields?.first?.text ?? ""
            self?.viewModel.renameSession(session.id, title: newTitle)
        })
        present(alert, animated: true)
    }

    func isNearBottom(threshold: CGFloat = 120) -> Bool {
        let visibleBottomY = tableView.contentOffset.y + tableView.bounds.height - tableView.adjustedContentInset.bottom
        let contentBottomY = tableView.contentSize.height
        return (contentBottomY - visibleBottomY) <= threshold
    }

    func scrollToBottom(animated: Bool) {
        guard !viewModel.messages.isEmpty else { return }
        tableView.layoutIfNeeded()
        let targetY = max(
            -tableView.adjustedContentInset.top,
            tableView.contentSize.height - tableView.bounds.height + tableView.adjustedContentInset.bottom
        )
        tableView.setContentOffset(CGPoint(x: 0, y: targetY), animated: animated)
    }
}

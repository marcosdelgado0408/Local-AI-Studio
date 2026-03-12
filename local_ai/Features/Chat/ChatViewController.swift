import UIKit
import PhotosUI
import UniformTypeIdentifiers
import PDFKit

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
    private let attachmentsPreviewScrollView = UIScrollView()
    private let attachmentsPreviewStackView = UIStackView()
    private let addButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let sendActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let modelLoadingOverlayView = UIView()
    private let modelLoadingCardView = UIView()
    private let modelLoadingTitleLabel = UILabel()
    private let modelLoadingSubtitleLabel = UILabel()
    private let modelLoadingSpinnerContainer = UIView()
    private let modelLoadingGlowView = UIView()
    private let modelLoadingTrackLayer = CAShapeLayer()
    private let modelLoadingArcLayer = CAShapeLayer()

    private let dimView = UIView()
    private let sidePanel = UIView()
    private let sessionsTableView = UITableView(frame: .zero, style: .plain)
    private let newChatButton = UIButton(type: .system)
    private var sidePanelLeadingConstraint: NSLayoutConstraint?
    private var isSidePanelOpen = false
    private var shouldAutoScrollToBottom = true
    private var isModelLoadingUI = false
    private var currentModelName: String
    private var pendingAttachments: [MessageAttachment] = [] {
        didSet {
            updateMetricsLabel()
            refreshAttachmentPreviews()
            updateComposerLayout()
        }
    }
    private var inputContainerHeightConstraint: NSLayoutConstraint?
    private var attachmentsPreviewHeightConstraint: NSLayoutConstraint?
    private lazy var dismissKeyboardTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideInput))
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        return gesture
    }()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        self.currentModelName = viewModel.activeModelDisplayName
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
        viewModel.load()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        layoutModelLoadingSpinnerLayers()
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
        configureModelLoadingDialog()
        configureKeyboardDismissGesture()
    }

    private func configureKeyboardDismissGesture() {
        view.addGestureRecognizer(dismissKeyboardTapGesture)
    }

    private func configureHeader() {
        menuButton.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        menuButton.tintColor = UIColor.white.withAlphaComponent(0.9)
        menuButton.addTarget(self, action: #selector(didTapMenu), for: .touchUpInside)

        titleLabel.text = shortModelName(from: viewModel.activeModelDisplayName)
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
        metricsLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        metricsLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        metricsLabel.textAlignment = .center
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        updateMetricsLabel()

        inputContainer.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 0.95)
        inputContainer.layer.cornerRadius = 20
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false

        attachmentsPreviewScrollView.showsHorizontalScrollIndicator = false
        attachmentsPreviewScrollView.backgroundColor = .clear
        attachmentsPreviewScrollView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsPreviewScrollView.isHidden = true

        attachmentsPreviewStackView.axis = .horizontal
        attachmentsPreviewStackView.alignment = .fill
        attachmentsPreviewStackView.spacing = 8
        attachmentsPreviewStackView.translatesAutoresizingMaskIntoConstraints = false

        addButton.setImage(UIImage(systemName: "plus"), for: .normal)
        addButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold), forImageIn: .normal)
        addButton.tintColor = UIColor.white.withAlphaComponent(0.85)
        addButton.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        addButton.layer.cornerRadius = 16
        addButton.contentHorizontalAlignment = .center
        addButton.contentVerticalAlignment = .center
        addButton.addTarget(self, action: #selector(didTapAddAttachment), for: .touchUpInside)
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

        attachmentsPreviewScrollView.addSubview(attachmentsPreviewStackView)
        inputContainer.addSubviews(attachmentsPreviewScrollView, addButton, textField, sendButton)
        sendButton.addSubview(sendActivityIndicator)

        NSLayoutConstraint.activate([
            attachmentsPreviewStackView.topAnchor.constraint(equalTo: attachmentsPreviewScrollView.topAnchor),
            attachmentsPreviewStackView.leadingAnchor.constraint(equalTo: attachmentsPreviewScrollView.leadingAnchor),
            attachmentsPreviewStackView.trailingAnchor.constraint(equalTo: attachmentsPreviewScrollView.trailingAnchor),
            attachmentsPreviewStackView.bottomAnchor.constraint(equalTo: attachmentsPreviewScrollView.bottomAnchor),
            attachmentsPreviewStackView.heightAnchor.constraint(equalTo: attachmentsPreviewScrollView.heightAnchor),
        ])

        refreshAttachmentPreviews()
        updateComposerLayout()
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

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: menuButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightHeaderSpacer.leadingAnchor, constant: -8),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),

            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            inputContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10),
            attachmentsPreviewScrollView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            attachmentsPreviewScrollView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
            attachmentsPreviewScrollView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -10),

            metricsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            metricsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            metricsLabel.bottomAnchor.constraint(equalTo: inputContainer.topAnchor, constant: -10),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 2),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: metricsLabel.topAnchor, constant: -8),

            addButton.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
            addButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor, constant: -1),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: addButton.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 48),
            sendButton.heightAnchor.constraint(equalToConstant: 48),
            sendActivityIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            sendActivityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),

            textField.leadingAnchor.constraint(equalTo: addButton.trailingAnchor, constant: 12),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            textField.topAnchor.constraint(equalTo: attachmentsPreviewScrollView.bottomAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -10),
            textField.heightAnchor.constraint(equalToConstant: 32),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sidePanel.topAnchor.constraint(equalTo: view.topAnchor),
            sidePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sidePanel.widthAnchor.constraint(equalToConstant: panelWidth),
        ])

        attachmentsPreviewHeightConstraint = attachmentsPreviewScrollView.heightAnchor.constraint(equalToConstant: 0)
        attachmentsPreviewHeightConstraint?.isActive = true
        inputContainerHeightConstraint = inputContainer.heightAnchor.constraint(equalToConstant: 58)
        inputContainerHeightConstraint?.isActive = true
    }

    private func bindViewModel() {
        viewModel.onMessagesUpdated = { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            guard self.shouldAutoScrollToBottom else { return }
            self.scrollToBottom(animated: false)
        }

        viewModel.onModelUpdated = { [weak self] modelName in
            self?.currentModelName = modelName
            self?.updateMetricsLabel()
            self?.titleLabel.text = self?.shortModelName(from: modelName)
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

        viewModel.onModelLoadingStateUpdated = { [weak self] loading in
            self?.applyModelLoadingState(loading)
        }
    }

    @objc
    private func didTapSend() {
        guard !isModelLoadingUI else { return }
        if viewModel.isGenerating {
            viewModel.stopGeneration()
            return
        }
        let text = textField.text ?? ""
        textField.text = nil
        let attachments = pendingAttachments
        pendingAttachments.removeAll()
        shouldAutoScrollToBottom = true
        viewModel.sendMessage(text, attachments: attachments)
    }

    @objc
    private func didTapAddAttachment() {
        guard !isModelLoadingUI else { return }
        view.endEditing(true)
        let sheet = UIAlertController(title: "Attach", message: nil, preferredStyle: .actionSheet)

        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.presentCamera()
        }
        takePhoto.setValue(UIImage(systemName: "camera.fill"), forKey: "image")

        let chooseLibrary = UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary()
        }
        chooseLibrary.setValue(UIImage(systemName: "photo.on.rectangle.angled"), forKey: "image")

        let attachDocument = UIAlertAction(title: "Attach Document", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        attachDocument.setValue(UIImage(systemName: "doc.fill"), forKey: "image")

        sheet.addAction(takePhoto)
        sheet.addAction(chooseLibrary)
        sheet.addAction(attachDocument)
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = addButton
            popover.sourceRect = addButton.bounds
        }
        present(sheet, animated: true)
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
        updateComposerInteractivity(isGenerating: generating)
        if generating {
            sendActivityIndicator.stopAnimating()
            sendButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
            sendButton.backgroundColor = UIColor(red: 0.89, green: 0.27, blue: 0.28, alpha: 1.0)
            sendButton.layer.shadowColor = UIColor(red: 0.89, green: 0.27, blue: 0.28, alpha: 1.0).cgColor
        } else {
            sendActivityIndicator.stopAnimating()
            sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
            sendButton.backgroundColor = UIColor(red: 0.10, green: 0.52, blue: 1.0, alpha: 1)
            sendButton.layer.shadowColor = UIColor(red: 0.10, green: 0.52, blue: 1.0, alpha: 1).cgColor
        }
    }

    func applyModelLoadingState(_ loading: Bool) {
        isModelLoadingUI = loading
        updateComposerInteractivity(isGenerating: viewModel.isGenerating)
        if loading {
            view.layoutIfNeeded()
            layoutModelLoadingSpinnerLayers()
            startModelLoadingAnimation()
            modelLoadingOverlayView.alpha = 0
            modelLoadingOverlayView.isHidden = false
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
                self.modelLoadingOverlayView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut]) {
                self.modelLoadingOverlayView.alpha = 0
            } completion: { _ in
                self.modelLoadingOverlayView.isHidden = true
                self.stopModelLoadingAnimation()
            }
        }
    }

    func updateComposerInteractivity(isGenerating: Bool) {
        sendButton.isEnabled = !isModelLoadingUI
        addButton.isEnabled = !isGenerating && !isModelLoadingUI
        textField.isEnabled = !isModelLoadingUI
    }

    func configureModelLoadingDialog() {
        modelLoadingOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        modelLoadingOverlayView.alpha = 0
        modelLoadingOverlayView.isHidden = true
        modelLoadingOverlayView.translatesAutoresizingMaskIntoConstraints = false

        modelLoadingCardView.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.16, alpha: 0.98)
        modelLoadingCardView.layer.cornerRadius = 20
        modelLoadingCardView.layer.borderWidth = 1
        modelLoadingCardView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        modelLoadingCardView.layer.shadowColor = UIColor.black.cgColor
        modelLoadingCardView.layer.shadowOpacity = 0.35
        modelLoadingCardView.layer.shadowRadius = 18
        modelLoadingCardView.layer.shadowOffset = CGSize(width: 0, height: 8)
        modelLoadingCardView.translatesAutoresizingMaskIntoConstraints = false

        modelLoadingTitleLabel.text = "Loading Model"
        modelLoadingTitleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
        modelLoadingTitleLabel.textColor = .white
        modelLoadingTitleLabel.textAlignment = .center
        modelLoadingTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        modelLoadingSubtitleLabel.text = "Preparing local AI for multimodal chat..."
        modelLoadingSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        modelLoadingSubtitleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        modelLoadingSubtitleLabel.textAlignment = .center
        modelLoadingSubtitleLabel.numberOfLines = 0
        modelLoadingSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        modelLoadingSpinnerContainer.translatesAutoresizingMaskIntoConstraints = false
        modelLoadingSpinnerContainer.backgroundColor = .clear

        modelLoadingGlowView.translatesAutoresizingMaskIntoConstraints = false
        modelLoadingGlowView.backgroundColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 0.22)
        modelLoadingGlowView.layer.cornerRadius = 30
        modelLoadingGlowView.layer.shadowColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1).cgColor
        modelLoadingGlowView.layer.shadowOpacity = 0.8
        modelLoadingGlowView.layer.shadowRadius = 14
        modelLoadingGlowView.layer.shadowOffset = .zero

        modelLoadingSpinnerContainer.addSubview(modelLoadingGlowView)
        modelLoadingSpinnerContainer.layer.addSublayer(modelLoadingTrackLayer)
        modelLoadingSpinnerContainer.layer.addSublayer(modelLoadingArcLayer)

        modelLoadingTrackLayer.fillColor = UIColor.clear.cgColor
        modelLoadingTrackLayer.strokeColor = UIColor.white.withAlphaComponent(0.30).cgColor
        modelLoadingTrackLayer.lineWidth = 5
        modelLoadingTrackLayer.lineCap = .round

        modelLoadingArcLayer.fillColor = UIColor.clear.cgColor
        modelLoadingArcLayer.strokeColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1).cgColor
        modelLoadingArcLayer.lineWidth = 5
        modelLoadingArcLayer.lineCap = .round
        modelLoadingArcLayer.strokeStart = 0.08
        modelLoadingArcLayer.strokeEnd = 0.72
        modelLoadingArcLayer.shadowColor = UIColor(red: 0.16, green: 0.62, blue: 1, alpha: 1).cgColor
        modelLoadingArcLayer.shadowOpacity = 0.8
        modelLoadingArcLayer.shadowRadius = 4
        modelLoadingArcLayer.shadowOffset = .zero

        modelLoadingCardView.addSubviews(modelLoadingTitleLabel, modelLoadingSpinnerContainer, modelLoadingSubtitleLabel)
        modelLoadingOverlayView.addSubview(modelLoadingCardView)
        view.addSubview(modelLoadingOverlayView)

        NSLayoutConstraint.activate([
            modelLoadingOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            modelLoadingOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modelLoadingOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modelLoadingOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            modelLoadingCardView.centerXAnchor.constraint(equalTo: modelLoadingOverlayView.centerXAnchor),
            modelLoadingCardView.centerYAnchor.constraint(equalTo: modelLoadingOverlayView.centerYAnchor),
            modelLoadingCardView.leadingAnchor.constraint(greaterThanOrEqualTo: modelLoadingOverlayView.leadingAnchor, constant: 26),
            modelLoadingCardView.trailingAnchor.constraint(lessThanOrEqualTo: modelLoadingOverlayView.trailingAnchor, constant: -26),
            modelLoadingCardView.widthAnchor.constraint(equalToConstant: 290),

            modelLoadingTitleLabel.topAnchor.constraint(equalTo: modelLoadingCardView.topAnchor, constant: 20),
            modelLoadingTitleLabel.leadingAnchor.constraint(equalTo: modelLoadingCardView.leadingAnchor, constant: 16),
            modelLoadingTitleLabel.trailingAnchor.constraint(equalTo: modelLoadingCardView.trailingAnchor, constant: -16),

            modelLoadingSpinnerContainer.topAnchor.constraint(equalTo: modelLoadingTitleLabel.bottomAnchor, constant: 14),
            modelLoadingSpinnerContainer.centerXAnchor.constraint(equalTo: modelLoadingCardView.centerXAnchor),
            modelLoadingSpinnerContainer.widthAnchor.constraint(equalToConstant: 64),
            modelLoadingSpinnerContainer.heightAnchor.constraint(equalToConstant: 64),

            modelLoadingGlowView.centerXAnchor.constraint(equalTo: modelLoadingSpinnerContainer.centerXAnchor),
            modelLoadingGlowView.centerYAnchor.constraint(equalTo: modelLoadingSpinnerContainer.centerYAnchor),
            modelLoadingGlowView.widthAnchor.constraint(equalToConstant: 60),
            modelLoadingGlowView.heightAnchor.constraint(equalToConstant: 60),

            modelLoadingSubtitleLabel.topAnchor.constraint(equalTo: modelLoadingSpinnerContainer.bottomAnchor, constant: 14),
            modelLoadingSubtitleLabel.leadingAnchor.constraint(equalTo: modelLoadingCardView.leadingAnchor, constant: 16),
            modelLoadingSubtitleLabel.trailingAnchor.constraint(equalTo: modelLoadingCardView.trailingAnchor, constant: -16),
            modelLoadingSubtitleLabel.bottomAnchor.constraint(equalTo: modelLoadingCardView.bottomAnchor, constant: -20),
        ])

        modelLoadingCardView.layoutIfNeeded()
        layoutModelLoadingSpinnerLayers()
    }

    func layoutModelLoadingSpinnerLayers() {
        guard modelLoadingSpinnerContainer.bounds.width > 0 else { return }
        let bounds = modelLoadingSpinnerContainer.bounds.insetBy(dx: 8, dy: 8)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 1.5 * .pi,
            clockwise: true
        )
        modelLoadingTrackLayer.frame = modelLoadingSpinnerContainer.bounds
        modelLoadingArcLayer.frame = modelLoadingSpinnerContainer.bounds
        modelLoadingTrackLayer.path = path.cgPath
        modelLoadingArcLayer.path = path.cgPath
    }

    func startModelLoadingAnimation() {
        modelLoadingSpinnerContainer.layer.removeAnimation(forKey: "spin")
        modelLoadingArcLayer.removeAnimation(forKey: "head")
        modelLoadingArcLayer.removeAnimation(forKey: "tail")
        modelLoadingGlowView.layer.removeAnimation(forKey: "glowPulse")

        let spin = CABasicAnimation(keyPath: "transform.rotation.z")
        spin.fromValue = 0
        spin.toValue = Double.pi * 2
        spin.duration = 1.05
        spin.repeatCount = .infinity
        spin.timingFunction = CAMediaTimingFunction(name: .linear)
        modelLoadingSpinnerContainer.layer.add(spin, forKey: "spin")

        let head = CABasicAnimation(keyPath: "strokeEnd")
        head.fromValue = 0.35
        head.toValue = 0.92
        head.duration = 0.75
        head.autoreverses = true
        head.repeatCount = .infinity
        head.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        modelLoadingArcLayer.add(head, forKey: "head")

        let tail = CABasicAnimation(keyPath: "strokeStart")
        tail.fromValue = 0.02
        tail.toValue = 0.46
        tail.duration = 0.75
        tail.autoreverses = true
        tail.repeatCount = .infinity
        tail.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        modelLoadingArcLayer.add(tail, forKey: "tail")

        let glowPulse = CABasicAnimation(keyPath: "opacity")
        glowPulse.fromValue = 0.28
        glowPulse.toValue = 0.62
        glowPulse.duration = 0.85
        glowPulse.autoreverses = true
        glowPulse.repeatCount = .infinity
        glowPulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        modelLoadingGlowView.layer.add(glowPulse, forKey: "glowPulse")
    }

    func stopModelLoadingAnimation() {
        modelLoadingSpinnerContainer.layer.removeAnimation(forKey: "spin")
        modelLoadingArcLayer.removeAnimation(forKey: "head")
        modelLoadingArcLayer.removeAnimation(forKey: "tail")
        modelLoadingGlowView.layer.removeAnimation(forKey: "glowPulse")
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

    func updateMetricsLabel() {
        if pendingAttachments.isEmpty {
            metricsLabel.text = "• Local"
        } else {
            metricsLabel.text = "• Local • \(pendingAttachments.count) attachment(s)"
        }
    }

    private func shortModelName(from raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("qwen") {
            if lower.contains("0.8b") {
                return "Qwen 3.5 0.8B"
            }
            if lower.contains("2b") {
                return "Qwen 3.5 2B"
            }
            return "Qwen 3.5"
        }
        return raw
    }

    func refreshAttachmentPreviews() {
        attachmentsPreviewStackView.arrangedSubviews.forEach {
            attachmentsPreviewStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for attachment in pendingAttachments {
            let preview = AttachmentPreviewView(
                attachment: attachment,
                removeAction: { [weak self] in
                    self?.removePendingAttachment(id: attachment.id)
                }
            )
            attachmentsPreviewStackView.addArrangedSubview(preview)
        }
    }

    func updateComposerLayout() {
        let hasAttachments = !pendingAttachments.isEmpty
        attachmentsPreviewScrollView.isHidden = !hasAttachments
        attachmentsPreviewHeightConstraint?.constant = hasAttachments ? 68 : 0
        inputContainerHeightConstraint?.constant = hasAttachments ? 134 : 58
        view.layoutIfNeeded()
    }

    func removePendingAttachment(id: UUID) {
        pendingAttachments.removeAll { $0.id == id }
    }

    func attachmentsDirectoryURL() -> URL {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let dir = base.appendingPathComponent("chat_attachments", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "Camera unavailable", message: "This device has no camera available.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }

    func presentPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 5
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func presentDocumentPicker() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = true
        present(picker, animated: true)
    }

    func makeImageAttachment(from image: UIImage, suggestedName: String?) -> MessageAttachment? {
        guard let imageData = image.jpegData(compressionQuality: 0.92) else { return nil }
        let id = UUID()
        let fallbackName = "photo-\(id.uuidString.prefix(8)).jpg"
        let fileName = suggestedName?.isEmpty == false ? suggestedName! : fallbackName
        let fileURL = attachmentsDirectoryURL().appendingPathComponent("\(id.uuidString)-\(fileName)")
        do {
            try imageData.write(to: fileURL, options: .atomic)
            return MessageAttachment(
                id: id,
                kind: .image,
                fileName: fileName,
                localFilePath: fileURL.path,
                extractedText: nil
            )
        } catch {
            return nil
        }
    }

    func makeDocumentAttachment(from sourceURL: URL) -> MessageAttachment? {
        let id = UUID()
        let fileName = sourceURL.lastPathComponent
        let destinationURL = attachmentsDirectoryURL().appendingPathComponent("\(id.uuidString)-\(fileName)")
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            let extractedText = extractDocumentText(from: destinationURL)
            return MessageAttachment(
                id: id,
                kind: .document,
                fileName: fileName,
                localFilePath: destinationURL.path,
                extractedText: extractedText
            )
        } catch {
            return nil
        }
    }

    func extractDocumentText(from url: URL) -> String? {
        if url.pathExtension.lowercased() == "pdf", let pdf = PDFDocument(url: url) {
            return trimmedExtractedText(pdf.string)
        }

        guard let data = try? Data(contentsOf: url) else { return nil }
        let text =
            String(data: data, encoding: .utf8) ??
            String(data: data, encoding: .utf16) ??
            String(data: data, encoding: .unicode) ??
            String(data: data, encoding: .ascii)
        return trimmedExtractedText(text)
    }

    func trimmedExtractedText(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(12_000))
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

private final class AttachmentPreviewView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    init(attachment: MessageAttachment, removeAction: @escaping () -> Void) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 72).isActive = true
        heightAnchor.constraint(equalToConstant: 68).isActive = true
        layer.cornerRadius = 12
        layer.masksToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.10)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        closeButton.layer.cornerRadius = 11
        closeButton.addAction(UIAction { _ in removeAction() }, for: .touchUpInside)

        addSubviews(imageView, titleLabel, closeButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            closeButton.widthAnchor.constraint(equalToConstant: 22),
            closeButton.heightAnchor.constraint(equalToConstant: 22),
        ])

        switch attachment.kind {
        case .image:
            imageView.image = UIImage(contentsOfFile: attachment.localFilePath)
            titleLabel.text = ""
            titleLabel.isHidden = true
        case .document:
            imageView.image = UIImage(systemName: "doc.text.fill")
            imageView.tintColor = UIColor.white.withAlphaComponent(0.90)
            imageView.backgroundColor = UIColor(red: 0.10, green: 0.14, blue: 0.22, alpha: 0.95)
            imageView.contentMode = .center
            titleLabel.text = attachment.fileName
            titleLabel.isHidden = false
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer { picker.dismiss(animated: true) }
        guard let image = info[.originalImage] as? UIImage else { return }
        if let attachment = makeImageAttachment(from: image, suggestedName: "camera.jpg") {
            pendingAttachments.append(attachment)
        } else {
            viewModel.onError?("Could not attach camera image.")
        }
    }
}

extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let itemProviders = results.map(\.itemProvider)
        for provider in itemProviders where provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self else { return }
                guard let image = object as? UIImage else { return }
                let attachment = self.makeImageAttachment(from: image, suggestedName: "library.jpg")
                DispatchQueue.main.async {
                    if let attachment {
                        self.pendingAttachments.append(attachment)
                    } else {
                        self.viewModel.onError?("Could not attach one of the selected photos.")
                    }
                }
            }
        }
    }
}

extension ChatViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard !urls.isEmpty else { return }
        for url in urls {
            let hadAccess = url.startAccessingSecurityScopedResource()
            let attachment = makeDocumentAttachment(from: url)
            if hadAccess {
                url.stopAccessingSecurityScopedResource()
            }
            if let attachment {
                pendingAttachments.append(attachment)
            } else {
                viewModel.onError?("Could not attach document \(url.lastPathComponent).")
            }
        }
    }
}

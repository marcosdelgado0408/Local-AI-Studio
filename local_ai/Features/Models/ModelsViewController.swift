import UIKit

final class ModelsViewController: UIViewController {
    private let viewModel: ModelsViewModel

    private let gradientLayer = CAGradientLayer()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()

    init(viewModel: ModelsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureTable()
        bindViewModel()
        viewModel.load()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    private func configureTable() {
        tableView.register(ModelTableViewCell.self, forCellReuseIdentifier: ModelTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.tableHeaderView = makeTableHeader()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func makeTableHeader() -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Models"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select your active engine"
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.7)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        headerContainer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 104)
        headerContainer.backgroundColor = .clear
        headerContainer.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: headerContainer.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
        ])
        return headerContainer
    }

    private func bindViewModel() {
        viewModel.onModelsUpdated = { [weak self] _ in
            self?.tableView.reloadData()
        }

        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }
}

extension ModelsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ModelTableViewCell.reuseID, for: indexPath) as? ModelTableViewCell else {
            return UITableViewCell()
        }

        let model = viewModel.models[indexPath.row]
        cell.configure(with: model)

        cell.onPrimaryAction = { [weak self] in
            self?.viewModel.primaryAction(for: model)
        }

        cell.onDeleteAction = { [weak self] in
            let alert = UIAlertController(
                title: "Delete Model",
                message: "Do you want to remove \(model.displayName) from local storage?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self?.viewModel.delete(model: model)
            })
            self?.present(alert, animated: true)
        }

        cell.onInfoAction = { [weak self] in
            let alert = UIAlertController(title: model.displayName, message: model.summary, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel))
            self?.present(alert, animated: true)
        }

        return cell
    }
}

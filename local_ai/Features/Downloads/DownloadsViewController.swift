import UIKit

final class DownloadsViewController: UIViewController {
    private let viewModel: DownloadsViewModel
    private let gradientLayer = CAGradientLayer()
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(viewModel: DownloadsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Downloads"
        configureBackground()

        tableView.register(DownloadTaskTableViewCell.self, forCellReuseIdentifier: DownloadTaskTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        viewModel.onTasksUpdated = { [weak self] _ in
            self?.tableView.reloadData()
        }
        viewModel.start()
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
}

extension DownloadsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DownloadTaskTableViewCell.reuseID, for: indexPath) as? DownloadTaskTableViewCell else {
            return UITableViewCell()
        }

        let task = viewModel.tasks[indexPath.row]
        cell.configure(with: task)
        cell.onPauseResume = { [weak self] in
            guard let self else { return }
            if task.state == .paused {
                self.viewModel.resume(task.id)
            } else {
                self.viewModel.pause(task.id)
            }
        }

        cell.onCancel = { [weak self] in
            self?.viewModel.cancel(task.id)
        }

        return cell
    }
}

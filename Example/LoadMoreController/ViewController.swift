//
//  ViewController.swift
//  InfiniteScrollingController
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import UIKit
import LoadMoreController

final class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var overlayView: UIView!
    @IBOutlet private weak var activityIndicatorSwitch: UISwitch!
    @IBOutlet weak var customIndicatorSwitch: UISwitch!
    
    // MARK: - Properties
    
    private let dataSource = DataSource()
    private var infiniteScrollingController: LoadMoreController?
    private var shouldLoadMore = true
    
    private lazy var customActivityIndicator: UIView = {
        let images = Array(0...4).compactMap( { "upyachka_\($0)"} ).compactMap({ UIImage(named: $0) }).compactMap({ $0 })
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 50.0, height: 50.0)))
        imageView.animationImages = images
        imageView.animationDuration = 0.35
        return imageView
    } ()
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infiniteScrollingController = LoadMoreController(scrollView: tableView,
                                                         triggeringThreshold: Dimensions.loadingIndicatorHeight,
                                                         loadMoreCallback: { [weak self] in self?.requestNextPage() }, shouldLoadMoreCallback: { [weak self] in return self?.shouldLoadMore ?? false })
        var contentInset = tableView.contentInset
        contentInset.bottom += overlayView.bounds.height
        tableView.contentInset = contentInset
    }
    
    private func requestNextPage() {
        dataSource.loadNextPage(completion: { [weak self] isLastPage in
            self?.shouldLoadMore = !isLastPage
            self?.infiniteScrollingController?.stop()
            self?.tableView.reloadData()
        })
    }
        
    // MARK: - Actions
    
    @IBAction private func valueChanged(_ sender: UISwitch) {
        infiniteScrollingController?.showsIndicatorOnLoadMore = sender.isOn
    }
    
    @IBAction private func customIndicatorValueChanged(_ sender: UISwitch) {
        infiniteScrollingController?.customActivityIndicatorView = sender.isOn ? customActivityIndicator : nil
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.numberOfRows(in: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        cell.textLabel?.text = dataSource.object(at: indexPath)
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource.titleForHeader(in: section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Dimensions.cellHeight
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
    }
}

extension ViewController {
    struct Constants {
        static let cellIdentifier = "tableCell"
    }
    
    struct Dimensions {
        static let cellHeight: CGFloat = 120.0
        static let loadingIndicatorHeight: CGFloat = 50.0
    }
}

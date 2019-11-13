//
//  LoadMoreController.swift
//  LoadMoreController
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import UIKit

typealias Completion = () -> Void

/// Utitlity class for handling scroll to bottom and showing loading indicator at the bottom of `UITableView`/`UICollectionView` content while loading the next page.
@objc final class LoadMoreController: NSObject {
    
    // MARK: - Properties
    
    @objc private(set) var onLoadMore: Completion?
    
    @objc var activityIndicatorColor: UIColor? {
        set {
            activityIndicatorView.color = newValue
        }
        get {
            return activityIndicatorView.color
        }
    }
    
    @objc var shouldLoadMore: Bool = true
    
    private weak var scrollView: UIScrollView?
    private let indicatorHeight: CGFloat
    
    private lazy var activityIndicatorView: UIActivityIndicatorView = { [unowned self] in
        let size = Dimensions.activityIndicatorSize
        let origin: CGPoint = {
            guard let scrollView = self.scrollView else { return .zero }
            return CGPoint(x: (scrollView.frame.width - size.width) / 2, y: scrollView.contentSize.height)
        }()
        
        let frame = CGRect(origin: origin, size: size)
        let activityIndicatorView = UIActivityIndicatorView(frame: frame)
        activityIndicatorView.color = .black
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        return activityIndicatorView
        }()
    
    /// KVO observation for `scrollView.contentOffset` to avoid interference with `UIScrollViewDelegateMethods`
    private var observation: NSKeyValueObservation?
    
    private var defaultY: CGFloat {
        return scrollView?.contentSize.height ?? 0.0
    }
    
    private var isHidden: Bool {
        guard let scrollView = scrollView else { return true }
        guard shouldLoadMore else { return true }
        return scrollView.contentSize.height < scrollView.frame.size.height
    }
    
    private var isAdjustedContentInset = false
    
    
    // MARK: - Lifecycle
    
    @objc init(scrollView: UIScrollView,
               indicatorHeight: CGFloat = Dimensions.activityIndicatorSize.height,
               loadMoreCallback: @escaping Completion) {
        self.scrollView = scrollView
        self.indicatorHeight = indicatorHeight
        self.onLoadMore = loadMoreCallback
        super.init()
        scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = isHidden
        observation = scrollView.observe(\.contentOffset, changeHandler: { [weak self] _, _ in self?.didScroll() })
    }
    
    // MARK: - Public methods
    
    func stop() {
        guard let scrollView = scrollView else { return }
        let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
        let offsetDelta = scrollView.contentOffset.y - contentDelta
        let needsAnimation = offsetDelta >= 0
        guard needsAnimation else {
            adjustContentInsetIfNeeded(indicatorHidden: true)
            activityIndicatorView.stopAnimating()
            return
        }
        UIView.animate(withDuration: Constants.animationDuration,
                       animations: { [weak self] in
                        self?.adjustContentInsetIfNeeded(indicatorHidden: true)
            },
                       completion: { [weak self] finished in
                        if finished { self?.activityIndicatorView.stopAnimating() }
        })
    }
    
    // MARK: - Private methods
    
    private func didScroll() {
        guard let scrollView = scrollView else { return }
        let offsetY = scrollView.contentOffset.y
        activityIndicatorView.isHidden = isHidden
        guard !activityIndicatorView.isHidden && offsetY >= 0 else { return }
        let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
        let offsetDelta = offsetY - contentDelta
        
        let newY = defaultY - offsetDelta
        if newY < scrollView.frame.height {
            activityIndicatorView.frame.origin.y = newY
        } else if activityIndicatorView.frame.origin.y != defaultY {
            activityIndicatorView.frame.origin.y = defaultY
        }
        
        
        let didScrollToIndicator = offsetY > contentDelta && offsetDelta >= indicatorHeight
        if !activityIndicatorView.isAnimating && didScrollToIndicator {
            activityIndicatorView.startAnimating()
            onLoadMore?()
        }
        
        if scrollView.isDecelerating && activityIndicatorView.isAnimating && !isAdjustedContentInset {
            UIView.animate(withDuration: Constants.animationDuration, animations: { [weak self] in
                self?.adjustContentInsetIfNeeded(indicatorHidden: self?.isHidden ?? false)
            })
        }
    }
    
    private func adjustContentInsetIfNeeded(indicatorHidden: Bool) {
        /// if indicator visibility hasn't changed, do nothing
        guard indicatorHidden == isAdjustedContentInset else { return }
        /// i.e. hide indicator afer loading, BUT there's still more content to be loaded.
        /// in this case we don't remove content inset for loading indicator to provide smooth scroll of content that was just loaded.
        if indicatorHidden && shouldLoadMore { return }
        
        guard let scrollView = scrollView else { return }
        isAdjustedContentInset = !indicatorHidden
        /// Add or subtract `indicatorHeight` from current `contentInset` depending on `indicatorHidden` flag.
        let bottomContentAdjustment = indicatorHidden ? -indicatorHeight : indicatorHeight
        var contentInset = scrollView.contentInset
        contentInset.bottom += bottomContentAdjustment
        scrollView.contentInset = contentInset
    }
}

// MARK: - Constants, Dimensions
private extension LoadMoreController {
    
    struct Constants {
        static let animationDuration: TimeInterval = 0.25
    }
    
    struct Dimensions {
        static var activityIndicatorSize: CGSize {
            return CGSize(width: 50.0, height: 50.0)
        }
    }
}

//
//  LoadMoreController.swift
//  LoadMoreController
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import UIKit

public typealias Completion = () -> Void
public typealias BoolResultCompletion = () -> Bool

/// Utitlity class for handling scroll to bottom and showing loading indicator at the bottom of `UITableView`/`UICollectionView` content while loading the next page.
@objc public final class LoadMoreController: NSObject {
    
    // MARK: - Properties
    
    @objc public var onLoadMore: Completion?
    @objc public var onShouldLoadMore: BoolResultCompletion?

    @objc public var activityIndicatorColor: UIColor? {
        set {
            defaultActivityIndicatorView.color = newValue
        }
        get {
            return defaultActivityIndicatorView.color
        }
    }
    
    @objc public var showsIndicatorOnLoadMore: Bool = true {
        didSet {
            rearrangeActivityIndicator()
        }
    }
    
    private weak var scrollView: UIScrollView?
    private let triggeringThreshold: CGFloat
    private var shouldLoadMore: Bool {
        return onShouldLoadMore?() ?? false
    }
    
    private lazy var defaultActivityIndicatorView: UIActivityIndicatorView = { [unowned self] in
        let size = Dimensions.activityIndicatorSize
        let origin: CGPoint = {
            guard let scrollView = self.scrollView else { return .zero }
            return CGPoint(x: (scrollView.frame.width - size.width) / 2, y: scrollView.contentSize.height)
        }()
        
        let frame = CGRect(origin: origin, size: size)
        let activityIndicatorView = UIActivityIndicatorView(frame: frame)
        activityIndicatorView.color = .black
        activityIndicatorView.startAnimating()
        activityIndicatorView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin]
        return activityIndicatorView
        }()
    
    
    @objc public var customActivityIndicatorView: UIView? {
        willSet {
            (activityIndicatorView as? Animatable)?.stopAnimating()
            activityIndicatorView.removeFromSuperview()
        }
        didSet {
            updateActivityIndicator()
        }
    }
    private var activityIndicatorView: UIView {
        return customActivityIndicatorView ?? defaultActivityIndicatorView
    }
    
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
    
    @objc public init(scrollView: UIScrollView,
                      triggeringThreshold: CGFloat,
                      loadMoreCallback: @escaping Completion,
                      shouldLoadMoreCallback: @escaping BoolResultCompletion) {
        self.scrollView = scrollView
        self.triggeringThreshold = triggeringThreshold
        self.onLoadMore = loadMoreCallback
        self.onShouldLoadMore = shouldLoadMoreCallback
        super.init()
        scrollView.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
        observation = scrollView.observe(\.contentOffset, changeHandler: { [weak self] _, _ in self?.didScroll() })
    }
    
    // MARK: - Public methods
    
    @objc public func stop() {
        guard let scrollView = scrollView else { return }
        let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
        let offsetDelta = scrollView.contentOffset.y - contentDelta
        let needsAnimation = offsetDelta >= 0
        guard needsAnimation else {
            adjustContentInsetIfNeeded(indicatorHidden: true)
            (activityIndicatorView as? Animatable)?.stopAnimating()
            activityIndicatorView.isHidden = true
            return
        }
        UIView.animate(withDuration: Constants.animationDuration,
                       animations: { [weak self] in
                        self?.adjustContentInsetIfNeeded(indicatorHidden: true)
            },
                       completion: { [weak self] finished in
                        if finished {
                            (self?.activityIndicatorView as? Animatable)?.stopAnimating()
                            self?.activityIndicatorView.isHidden = true
                        }
        })
    }
    
    // MARK: - Private methods
        
    private func didScroll() {
        guard let scrollView = scrollView else { return }
        let offsetY = scrollView.contentOffset.y
                guard !isHidden && offsetY >= 0 else {
            return
        }
        let contentDelta = scrollView.contentSize.height - scrollView.frame.size.height
        let offsetDelta = offsetY - contentDelta
        
        let newY = defaultY - offsetDelta
        if newY < scrollView.frame.height {
            activityIndicatorView.frame.origin.y = newY
        } else if activityIndicatorView.frame.origin.y != defaultY {
            activityIndicatorView.frame.origin.y = defaultY
        }
        
        let didScrollToIndicator = offsetY > contentDelta && offsetDelta >= triggeringThreshold
        if activityIndicatorView.isHidden != isHidden && didScrollToIndicator {
            activityIndicatorView.isHidden = isHidden
            isHidden
                ? (activityIndicatorView as? Animatable)?.stopAnimating()
                : (activityIndicatorView as? Animatable)?.startAnimating()
            onLoadMore?()
        }
        if scrollView.isDecelerating && !activityIndicatorView.isHidden && !isAdjustedContentInset {
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
        /// Add or subtract `triggeringThreshold` from current `contentInset` depending on `indicatorHidden` flag.
        let bottomContentAdjustment = indicatorHidden ? -triggeringThreshold : triggeringThreshold
        var contentInset = scrollView.contentInset
        contentInset.bottom += bottomContentAdjustment
        scrollView.contentInset = contentInset
    }
    
    private func updateActivityIndicator() {
        if let customView = customActivityIndicatorView, customView.superview != scrollView {
            customView.center = CGPoint(x: UIScreen.main.bounds.width / 2.0, y: triggeringThreshold / 2.0)
        }
        activityIndicatorView.isHidden = true
        rearrangeActivityIndicator()
    }
    
    private func rearrangeActivityIndicator() {
        guard showsIndicatorOnLoadMore else {
            activityIndicatorView.removeFromSuperview()
            return
        }
        if activityIndicatorView.superview != scrollView {
            scrollView?.addSubview(activityIndicatorView)
        }
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

// MARK: - Animatable

public protocol Animatable: class {
    func startAnimating()
    func stopAnimating()
    var isAnimating: Bool { get }
}

extension UIActivityIndicatorView: Animatable {}

extension UIImageView: Animatable {}

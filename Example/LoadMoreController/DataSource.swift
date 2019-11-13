//
//  DataSource.swift
//  InfiniteScrollingController
//
//  Copyright (c) 2019 dashdevs.com. All rights reserved.
//

import Foundation

final class DataSource {
    
    private var currentPage: Int = 0
    
    func numberOfSections() -> Int {
        return currentPage + 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return Constants.pageSize
    }
    
    func object(at indexPath: IndexPath) -> String {
        let index = indexPath.section * Constants.pageSize + indexPath.row
        return "Item \(Constants.items[index])"
    }
    
    func titleForHeader(in section: Int) -> String? {
        return "SECTION \(section + 1)"
    }
    
    func loadNextPage(completion: @escaping ((_ isLastPage: Bool) -> Void)) {
        let maxPages = Constants.items.count / Constants.pageSize
        guard currentPage + 1 < maxPages else {
            completion(true)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
            self?.currentPage += 1;
            completion(false)
        })
    }
}
 
private extension DataSource {
    struct Constants {
        static let pageSize = 10
        static let items: [String] = [
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "10",
            "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
            "21", "22", "23", "24", "25", "26", "27", "28", "29", "30"
        ]
    }
}

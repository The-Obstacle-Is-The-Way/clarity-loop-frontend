//
//  ViewState.swift
//  clarity-loop-frontend
//
//  Created by Raymond Jung on 6/7/25.
//

import Foundation

/// A generic enum to represent the state of a view that loads data asynchronously.
/// This provides a consistent way to handle loading, error, and content states across different features.
enum ViewState<T> {
    /// The view is idle and has not yet started loading.
    case idle
    
    /// The view is currently loading data.
    case loading
    
    /// The view has successfully loaded the data.
    case loaded(T)
    
    /// The view encountered an error while loading data.
    case error(String)
    
    /// The view loaded successfully, but there is no data to display.
    case empty
} 
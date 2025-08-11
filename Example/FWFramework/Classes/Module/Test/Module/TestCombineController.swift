//
//  TestCombineController.swift
//  FWFramework_Example
//
//  Created by dayong on 2025/8/11.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import FWFramework
import Combine

class Counter {
    var count = CurrentValueSubject<Int, Never>(0)
    
    func increment() {
        count.send(count.value + 1)
    }
    
    func decrement() {
        count.send(count.value - 1)
    }
}

class TestCombineController: UIViewController, ViewControllerProtocol {
    let counter = Counter()
    var cancellable: AnyCancellable?
    
    private lazy var countLabel: UILabel = {
        let result = UILabel()
        result.textColor = AppTheme.textColor
        result.font = UIFont.systemFont(ofSize: 15)
        result.textAlignment = .center
        return result
    }()
    
    private lazy var incrementButton: UIButton = {
        let button = AppTheme.largeButton()
        button.app.setTitle("Increment")
        button.app.addTouch { [weak self] _ in
            self?.counter.increment()
        }
        return button
    }()
    
    private lazy var decrementButton: UIButton = {
        let button = AppTheme.largeButton()
        button.app.setTitle("Decrement")
        button.app.addTouch { [weak self] _ in
            self?.counter.decrement()
        }
        return button
    }()
    
    func setupSubviews() {
        view.addSubview(countLabel)
        view.addSubview(incrementButton)
        view.addSubview(decrementButton)
    }
    
    func setupLayout() {
        countLabel.layoutChain
            .centerX()
            .top(toSafeArea: 20)
        
        incrementButton.layoutChain
            .top(toViewBottom: countLabel, offset: 20)
            .centerX()
        
        decrementButton.layoutChain
            .top(toViewBottom: incrementButton, offset: 20)
            .centerX()
    }
    
    func setupData() {
        countLabel.text = "\(counter.count.value)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupData()
        cancellable = counter.count.sink(receiveValue: { [weak self] value in
            self?.setupData()
        })
    }
    
    deinit {
        cancellable?.cancel()
    }
}

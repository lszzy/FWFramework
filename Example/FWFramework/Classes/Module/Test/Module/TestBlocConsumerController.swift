//
//  TestBlocConsumerController.swift
//  FWFramework_Example
//
//  Created by dayong on 2025/8/11.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import FWFramework
import SwiftUI

// MARK: - TestBlocConsumerController
class TestBlocConsumerController: UIViewController, ViewControllerProtocol {
    private var bloc = CounterCubit()

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
            guard let bloc = self?.bloc else { return }

            bloc.increment()
            if bloc.state > 5 {
                for _ in 0..<6 {
                    bloc.decrement()
                }
            }
        }
        return button
    }()

    private lazy var decrementButton: UIButton = {
        let button = AppTheme.largeButton()
        button.app.setTitle("Decrement")
        button.app.addTouch { [weak self] sender in
            guard let bloc = sender.blocConsumer(of: CounterCubit.self) else { return }

            bloc.decrement()
            if bloc.state < -5 {
                for _ in 0..<6 {
                    bloc.increment()
                }
            }
        }
        return button
    }()

    private lazy var counterBlocView: UIView = CounterBlocView().wrappedHostingView()

    private lazy var requestBlocView: UIView = RequestBlocView().wrappedHostingView()

    func setupSubviews() {
        view.addSubview(countLabel)
        view.addSubview(incrementButton)
        view.addSubview(decrementButton)
        view.addSubview(counterBlocView)
        view.addSubview(requestBlocView)
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

        counterBlocView.layoutChain
            .top(toViewBottom: decrementButton, offset: 20)
            .horizontal()
            .height(100)

        requestBlocView.layoutChain
            .top(toViewBottom: counterBlocView, offset: 20)
            .horizontal()
            .height(100)

        blocConsumer(bloc: bloc) { [weak self] _, state in
            self?.countLabel.text = "UIKit: \(state)"
        }
    }
}

// MARK: - CounterCubit
class CounterCubit: Cubit<Int> {
    init() {
        super.init(0)
    }

    func increment() {
        emit(state + 1)
    }

    func decrement() {
        emit(state - 1)
    }
}

// MARK: - CounterBloc
enum CounterEvent {
    case increment
    case decrement
}

struct CounterState: Equatable {
    let count: Int

    func copyWith(count: Int?) -> CounterState {
        CounterState(count: count ?? self.count)
    }
}

class CounterBloc: Bloc<CounterEvent, CounterState> {
    init() {
        super.init(CounterState(count: 0))
    }

    override func mapEventToState(_ event: CounterEvent, emit: @escaping (CounterState) -> Void) {
        switch event {
        case .increment:
            emit(state.copyWith(count: state.count + 1))
        case .decrement:
            emit(state.copyWith(count: state.count - 1))
        }
    }
}

struct CounterBlocView: View {
    var body: some View {
        BlocConsumer(bloc: CounterBloc()) { bloc, state in
            VStack {
                Text("SwiftUI: \(state.count)")
                Button(action: {
                    bloc.add(.increment)
                    if bloc.state.count > 5 {
                        for _ in 0..<6 {
                            bloc.add(.decrement)
                        }
                    }
                }, label: {
                    Text("Increment")
                })
                Button(action: {
                    bloc.add(.decrement)
                    if bloc.state.count < -5 {
                        for _ in 0..<6 {
                            bloc.add(.increment)
                        }
                    }
                }, label: {
                    Text("Decrement")
                })
            }
        }
    }
}

// MARK: - RequestBloc
enum RequestEvent {
    case query
}

typealias RequestState = ViewLoadingState<String>

class RequestBloc: Bloc<RequestEvent, RequestState> {
    private var failedCount = 0

    init() {
        super.init(.ready)
    }

    override func mapEventToState(_ event: RequestEvent, emit: @escaping (RequestState) -> Void) {
        switch event {
        case .query:
            emit(.loading)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let success = [true, false, false].randomElement()!
                if success {
                    emit(.success("Success"))
                } else {
                    self.failedCount += 1
                    emit(.failure(NSError(domain: "RequestBloc", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed \(self.failedCount)"])))
                }
            }
        }
    }
}

struct RequestBlocView: View {
    var body: some View {
        BlocConsumer(bloc: RequestBloc()) { bloc, _ in
            switch bloc.state {
            case .ready:
                InvisibleView()
            case .loading:
                LoadingPluginView()
            case let .success(object):
                Text(object ?? "")
            case .failure:
                RequestBlocFailureView()
            }
        } listener: { bloc in
            if bloc.state == .ready {
                bloc.add(.query)
            }
        }
    }
}

struct RequestBlocFailureView: View {
    @EnvironmentObject var bloc: RequestBloc

    var body: some View {
        Button(bloc.state.error?.localizedDescription ?? "") {
            bloc.add(.query)
        }
    }
}

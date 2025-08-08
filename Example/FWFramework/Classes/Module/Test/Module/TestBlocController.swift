//
//  TestBlocController.swift
//  FWFramework_Example
//
//  Created by dayong on 2025/8/7.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import FWFramework
import SwiftUI

class TestBlocController: UIViewController, ViewControllerProtocol {
    func setupSubviews() {
        let hostingView = TestBlocView()
            .wrappedHostingView()
        view.addSubview(hostingView)
        hostingView.app.layoutChain
            .horizontal()
            .top(toSafeArea: .zero)
            .bottom()
    }
}

struct TestBlocView: View {
    var body: some View {
        ScrollView {
            CubitContentView()
                .padding(.top, 30)
            BlocContentView()
                .padding(.top, 30)
        }
    }
}

// MARK: - Cubit
class CounterCubit: Cubit<Int> {
    init() {
        super.init(state: 0)
    }

    func increment() {
        emit(state: state + 1)
    }

    func decrement() {
        emit(state: state - 1)
    }
}

struct CubitContentView: View {
    var body: some View {
        BlocView(builder: { cubit in
            VStack {
                Text("Cubit")
                Button(action: {
                    cubit.increment()
                }, label: {
                    Text("Increment")
                })
                Button(action: {
                    cubit.decrement()
                }, label: {
                    Text("Decrement")
                })
                Text("Count: \(cubit.state)")
            }
        }, base: CounterCubit())
    }
}

// MARK: - Bloc
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
        super.init(initialState: CounterState(count: 0))
    }

    override func mapEventToState(event: CounterEvent) -> CounterState {
        switch event {
        case .increment:
            return state.copyWith(count: state.count + 1)
        case .decrement:
            return state.copyWith(count: state.count - 1)
        }
    }
}

struct BlocContentView: View {
    var body: some View {
        BlocView(builder: { bloc in
            let isPresented = Binding.constant(bloc.state.count < -6)
            CounterView()
                .alert(isPresented: isPresented) {
                    Alert(
                        title: Text("Hi"),
                        message: Text("Message"),
                        dismissButton: .cancel {
                            for _ in 0..<6 {
                                bloc.add(event: .increment)
                            }
                        }
                    )
                }
        }, action: { bloc in
            print(bloc.state.count)
        }, base: CounterBloc())
    }
}

struct CounterView: View {
    @EnvironmentObject var bloc: CounterBloc

    var body: some View {
        if bloc.state.count > 5 {
            LimitView()
        } else {
            OperationView()
        }
    }
}

struct LimitView: View {
    @EnvironmentObject var bloc: CounterBloc

    var body: some View {
        VStack {
            Text("Hooora")
            Button(action: {
                for _ in 0..<6 {
                    bloc.add(event: .decrement)
                }
            }, label: {
                Text("Reset")
            })
        }
    }
}

struct OperationView: View {
    @EnvironmentObject var bloc: CounterBloc

    var body: some View {
        VStack {
            Text("Bloc")
            Button(action: {
                bloc.add(event: .increment)
            }, label: {
                Text("Send Increment event")
            })
            Button(action: {
                bloc.add(event: .decrement)
            }, label: {
                Text("Send Decrement event")
            })
            Text("Count: \(bloc.state.count)")
        }
    }
}

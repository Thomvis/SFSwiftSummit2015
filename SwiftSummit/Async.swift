//
//  Async.swift
//  SwiftSummit
//
//  Created by Thomas Visser on 30/10/15.
//  Copyright © 2015 Thomas Visser. All rights reserved.
//

import Foundation

protocol AsyncType {
    typealias Res
    
    var result: Res? { get }
    
    init(@noescape scope: (Res -> Void) -> Void)
    
    func onComplete(callback: Res -> Void) -> Self
}

class Async<Result>: AsyncType {
    
    typealias Callback = Result -> Void
    
    private(set) var result: Result?
    private var callbacks = [Callback]()
    
    required init(@noescape scope: (Result -> Void) -> Void) {
        scope { res in
            self.result = res
            
            for callback in self.callbacks {
                callback(res)
            }
            self.callbacks.removeAll()
        }
    }
    
    func onComplete(callback: Result -> Void) -> Self {
        let mainCallback: Callback = { res in
            dispatch_async(dispatch_get_main_queue()) {
                callback(res)
            }
        }
        
        if let result = result {
            mainCallback(result)
        } else {
            callbacks.append(mainCallback)
        }
        
        return self
    }
    
}

import Result

class Future<Value, Error: ErrorType>: Async<Result<Value,Error>> {
    
    required init(@noescape scope: (Result<Value, Error> -> Void) -> Void) {
        super.init(scope: scope)
    }
    
}

extension AsyncType where Res: ResultType {
    
    func onSuccess(callback: Res.Value -> Void) -> Self {
        return onComplete { res in
            res.analysis(ifSuccess: { val -> Void in
                callback(val)
            }, ifFailure: { _ in })
        }
    }
    
    func onFailure(callback: Res.Error -> Void) -> Self {
        return onComplete { res in
            res.analysis(ifSuccess: { _ in }, ifFailure: { error -> Void in
                callback(error)
            })
        }
    }
    
    func map<U>(transform: Self.Res.Value -> U) -> Future<U, Self.Res.Error> {
        return Future { completion in
            onComplete { res in
                res.analysis(ifSuccess: { val -> Void in
                    completion(Result(value: transform(val)))
                    }, ifFailure: { error -> Void in
                        completion(Result(error: error))
                })
            }
        }
    }
    
    func flatMap<U>(transform: Self.Res.Value -> Result<U, Self.Res.Error>) -> Future<U, Self.Res.Error> {
        return Future { completion in
            self.onComplete { res in
                res.analysis(ifSuccess: { val -> Void in
                    transform(val).analysis(ifSuccess: { val in
                        completion(Result(value: val))
                        }, ifFailure: { error in
                            completion(Result(error: error))
                    });
                    }, ifFailure: { error -> Void in
                        completion(Result(error: error))
                })
            }
        }
    }
    
    func flatMap<U>(transform: Self.Res.Value -> Future<U, Self.Res.Error>) -> Future<U, Self.Res.Error> {
        return Future { completion in
            self.onSuccess { value in
                transform(value).onSuccess { val in
                    completion(Result(value: val))
                    }.onFailure { err in
                        completion(Result(error: err))
                }
                }.onFailure { error in
                    completion(Result(error: error))
            }
        }
    }
    
}


extension SequenceType where Generator.Element: AsyncType, Generator.Element.Res : ResultType {
    
    func fold<R>(zero: R, f: (R, Generator.Element.Res.Value) -> R) -> Future<R, Generator.Element.Res.Error> {
        return reduce(Future { $0(Result(value: zero)) }) { zero, elem in
            return zero.flatMap { zeroVal in
                elem.map { elemVal in
                    return f(zeroVal, elemVal)
                }
            }
        }
    }
    
    func sequence() -> Future<[Generator.Element.Res.Value], Generator.Element.Res.Error> {
        return fold(Array<Generator.Element.Res.Value>()) { (acc, elem) -> [Generator.Element.Res.Value] in
            return acc + [elem]
        }
    }
}



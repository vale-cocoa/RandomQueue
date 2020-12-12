//
//  RandomQueuePerformanceTests.swift
//  RandomQueueTests
//
//  Created by Valeriano Della Longa on 2020/12/11.
//  Copyright © 2020 Valeriano Della Longa. All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import XCTest
import RandomQueue

final class RandomQueuePerformanceTests: XCTestCase {
    var sut: (outerCount: Int, innerCount: Int)!
    
    func testRandomQueuePerformanceAtSmallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .randomQueue) }
    }
    
    func testArrayPerformanceAtSmallCount() {
        whenSmallCount()
        measure { performanceLoop(for: .arrayBased) }
    }
    
    func testRandomQueuePreformanceAtLargeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .randomQueue) }

    }
    
    func testArrayPerformanceAtLargeCount() {
        whenLargeCount()
        measure { performanceLoop(for: .arrayBased) }
    }
    
    // MARK: - Private helpers
    private func whenSmallCount() {
        sut = (10_000, 20)
    }
    
    private func whenLargeCount() {
        sut = (10, 20_000)
    }
    
    private func performanceLoop(for kind: KindOfTestable) {
        var accumulator = 0
        for _ in 1...sut.outerCount {
            var testable = kind.newTestable(capacity: sut.innerCount)
            for i in 1...sut.innerCount {
                testable.enqueue(i)
                accumulator ^= i
            }
            for _ in 1...sut.innerCount {
                accumulator ^= (testable.dequeue() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private enum KindOfTestable {
        case randomQueue
        case arrayBased
        
        func newTestable(capacity: Int) -> PerformanceTestable {
            switch self {
            case .randomQueue:
                return RandomQueue<Int>(capacity: capacity)
            case .arrayBased:
                return Array<Int>(capacity: capacity)
            }
        }
    }
    
}

fileprivate protocol PerformanceTestable {
    init(capacity: Int)
    
    var first: Int? { get }
    
    var last: Int? { get }
    
    mutating func enqueue(_ newElement: Int)
    
    @discardableResult
    mutating func dequeue() -> Int?
}

extension RandomQueue: PerformanceTestable where Element == Int {
    init(capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }
    
}

extension Array: PerformanceTestable where Element == Int {
    init(capacity: Int) {
        self.init()
        reserveCapacity(capacity)
    }
    
    mutating func enqueue(_ newElement: Int) {
        append(newElement)
        if let randomIdx = indices.randomElement() {
            swapAt(endIndex - 1, randomIdx)
        }
    }
    
    mutating func dequeue() -> Int? {
        defer {
            if let randomIdx = indices.randomElement() {
                swapAt(endIndex - 1, randomIdx)
            }
        }
        
        return popLast()
    }
    
}

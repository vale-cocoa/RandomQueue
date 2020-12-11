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
    // MARK: - Performance tests
    func testRandomQueuePerformanceAtSmallCount() {
        measure(performanceLoopRandomQueueSmallCount)
    }
    
    func testArrayPerformanceAtSmallCount() {
        measure(performanceLoopArraySmallCount)
    }
    
    func testRandomQueuePreformanceAtLargeCount() {
        measure(performanceLoopRandomQueueLargeCount)
    }
    
    func testArrayPerformanceAtLargeCount() {
        measure(performanceLoopArrayLargeCount)
    }
    
    // MARK: - Private helpers
    private func performanceLoopRandomQueueSmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var queue = RandomQueue<Int>()
            queue.reserveCapacity(innerCount)
            for i in 1...innerCount {
                queue.enqueue(i)
                accumulator ^= (i)
            }
            for _ in 1...innerCount {
                accumulator ^= (queue.peek() ?? 0)
                queue.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArraySmallCount() {
        let outerCount: Int = 10_000
        let innerCount: Int = 20
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                if let randomIdx = array.indices.randomElement() {
                    array.swapAt(array.endIndex - 1, randomIdx)
                }
                accumulator ^= (array.popLast() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopRandomQueueLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var queue = RandomQueue<Int>()
            queue.reserveCapacity(innerCount)
            for i in 1...innerCount {
                queue.enqueue(i)
                accumulator ^= (i)
            }
            for _ in 1...innerCount {
                accumulator ^= (queue.peek() ?? 0)
                queue.dequeue()
            }
        }
        XCTAssert(accumulator == 0)
    }
    
    private func performanceLoopArrayLargeCount() {
        let outerCount: Int = 10
        let innerCount: Int = 20_000
        var accumulator = 0
        for _ in 1...outerCount {
            var array = Array<Int>()
            array.reserveCapacity(innerCount)
            for i in 1...innerCount {
                array.append(i)
                accumulator ^= (array.last ?? 0)
            }
            for _ in 1...innerCount {
                if let randomIdx = array.indices.randomElement() {
                    array.swapAt(array.endIndex - 1, randomIdx)
                }
                accumulator ^= (array.popLast() ?? 0)
            }
        }
        XCTAssert(accumulator == 0)
    }
    
}

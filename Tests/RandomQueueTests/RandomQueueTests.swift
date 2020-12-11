//
//  RandomQueueTests.swift
//  RandomQueueTests
//
//  Created by Valeriano Della Longa on 2020/11/30.
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
@testable import RandomQueue
@testable import CircularBuffer
@testable import Queue

final class RandomQueueTests: XCTestCase {
    var sut: RandomQueue<Int>!
    
    override func setUp() {
        super.setUp()
        
        sut = []
    }
    
    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialize tests
    func testInit() {
        sut = RandomQueue<Int>()
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
        XCTAssertNil(sut.first)
        XCTAssertNil(sut.last)
        XCTAssertNil(sut.storage)
    }
    
    func testInitFromSequence() {
        let elements = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let sequence = AnySequence { () -> AnyIterator<Int> in
            var idx = elements.startIndex
            
            return AnyIterator {
                guard idx < elements.endIndex else { return nil }
                
                defer { idx += 1 }
                
                return elements[idx]
            }
        }
        
        // when sequence implements withContiguousStorageIfAvailable(_:)
        sut = RandomQueue(elements)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.sorted().elementsEqual(elements))
        
        // when sequence doesn't implement withContiguousStorageIfAvailable(_:)
        sut = RandomQueue(AnySequence(elements))
        XCTAssertTrue(sut.sorted().elementsEqual(elements))
        
        // when sequence's underestimated is less than its elements count:
        XCTAssertLessThan(sequence.underestimatedCount, elements.count)
        sut = RandomQueue(sequence)
        XCTAssertTrue(sut.sorted().elementsEqual(elements))
    }
    
    func testInitFromArrayLiteral() {
        sut = []
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        let elements = [1, 2, 3, 4, 5]
        sut = [1, 2, 3, 4, 5]
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.sorted().elementsEqual(elements))
    }
    
    func testInitRepeatingCount() {
        sut = RandomQueue<Int>(repeating: 1, count: 0)
        XCTAssertNotNil(sut)
        XCTAssertTrue(sut.isEmpty)
        
        sut = RandomQueue(repeating: 10, count: 10)
        XCTAssertNotNil(sut)
        XCTAssertEqual(Array(sut), Array(repeating: 10, count: 10))
    }
    
    // MARK: - count, isEmpty, first and last properties tests
    func testCount() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.count, sut.storage?.count ?? 0)
        
        sut = RandomQueue([1, 2, 3, 4])
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.count, 4)
        XCTAssertEqual(sut.count, sut.storage?.count ?? 0)
    }
    
    func testIsEmpty() {
        XCTAssertEqual(sut.count, 0)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        XCTAssertEqual(sut.isEmpty, sut.storage?.isEmpty ?? true)
        
        sut.append(1)
        XCTAssertGreaterThan(sut.count, 0)
        XCTAssertFalse(sut.isEmpty)
        XCTAssertNotNil(sut.storage)
        XCTAssertEqual(sut.isEmpty, sut.storage?.isEmpty ?? true)
    }
    
    func testFirst() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = RandomQueue([1])
        XCTAssertEqual(sut.first, 1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = RandomQueue([1, 2, 3])
        XCTAssertEqual(sut.first, sut.storage?.first)
        XCTAssertGreaterThan(sut.count, 1)
        XCTAssertNotEqual(sut.first, sut.last)
    }
    
    func testLast() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.first)
        XCTAssertEqual(sut.count, 0)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = RandomQueue([1])
        XCTAssertEqual(sut.last, 1)
        XCTAssertEqual(sut.count, 1)
        XCTAssertEqual(sut.first, sut.last)
        
        sut = RandomQueue([1, 2, 3])
        XCTAssertEqual(sut.last, sut.storage?.last)
        XCTAssertGreaterThan(sut.count, 1)
        XCTAssertNotEqual(sut.first, sut.last)
    }
    
    // MARK: - enqueue(_:) and enqueue(contentsOf:) tests
    func testEnqueueElement() {
        var prevCount = sut.count
        sut.enqueue(1)
        XCTAssertEqual(sut.count, prevCount + 1)
        XCTAssertTrue(sut.contains(1))
        
        prevCount = sut.count
        sut.enqueue(2)
        XCTAssertEqual(sut.count, prevCount + 1)
        XCTAssertTrue(sut.contains(2))
        
        // value semantics:
        var copy = sut!
        copy.enqueue(3)
        assertValueSemantics(copy)
    }
    
    func testEnqueueSequence() {
        let elements = [1, 2, 3, 4, 5]
        let prevCount = sut.count
        sut.enqueue(contentsOf: elements)
        XCTAssertEqual(sut.count, prevCount + 5)
        // Since after having stored elements, a random element is put as first,
        // checking for equality requires to first sort sut elements:
        XCTAssertEqual(Array(sut).sorted(), elements)
        
        // value semantics:
        var copy = sut!
        copy.enqueue(contentsOf: [6, 7, 8, 9, 10])
        assertValueSemantics(copy)
    }
    
    
    // MARK: - dequeue()
    func testDequeueElement() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.dequeue())
        
        sut.enqueue(1)
        var prevPeeked = sut.peek()
        var prevCount = sut.count
        XCTAssertEqual(sut.dequeue(), prevPeeked)
        XCTAssertEqual(sut.count, prevCount - 1)
        XCTAssertNotEqual(sut.peek(), prevPeeked)
        
        sut.enqueue(contentsOf: [1, 2, 3, 4, 5])
        prevPeeked = sut.peek()
        prevCount = sut.count
        XCTAssertEqual(sut.dequeue(), prevPeeked)
        XCTAssertEqual(sut.count, prevCount - 1)
        XCTAssertNotEqual(sut.peek(), prevPeeked)
        var expectedResult = [1, 2, 3, 4, 5]
        expectedResult.removeAll(where: { $0 == prevPeeked })
        // Checking for elements left in sut requires to sort them
        // since right before the dequeue operation an element stored at
        // a random position is swapped with the one at first position.
        XCTAssertEqual(Array(sut).sorted(), expectedResult)
        
        // value semantics:
        var copy = sut!
        copy.dequeue()
        assertValueSemantics(copy)
    }
    
    // MARK: - Collection, BidirectionalCollection, MutableCollection, RandomAccessCollection tests
    // MARK: - Index tests
    func testIndex() {
        // startIndex, endIndex
        XCTAssertTrue(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
        XCTAssertEqual(sut.startIndex, sut.endIndex)
        XCTAssertEqual(sut.endIndex, sut.count)
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertFalse(sut.isEmpty)
        XCTAssertEqual(sut.startIndex, 0)
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.endIndex, sut.count)
        
        // index(after:), index(before:),
        //formIndex(after:), formIndexBefore(:)
        
        var idx = sut.startIndex
        let nextIdx = sut.index(after: idx)
        XCTAssertGreaterThan(nextIdx, idx)
        XCTAssertEqual(nextIdx, idx + 1)
        
        sut.formIndex(after: &idx)
        XCTAssertEqual(idx, nextIdx)
        let beforeIdx = sut.index(before: idx)
        XCTAssertLessThan(beforeIdx, idx)
        XCTAssertEqual(beforeIdx, idx - 1)
        
        sut.formIndex(before: &idx)
        XCTAssertEqual(idx, beforeIdx)
        XCTAssertLessThan(idx, nextIdx)
        
        // index(_:, offsetBy:)
        let offsetBy3 = sut.index(sut.startIndex, offsetBy: 3)
        idx = sut.startIndex
        for _ in 1...3 {
            sut.formIndex(after: &idx)
        }
        XCTAssertEqual(offsetBy3, idx)
        
        let offsetByNegative3 = sut.index(sut.endIndex, offsetBy: -3)
        idx = sut.endIndex
        for _ in 1...3 {
            sut.formIndex(before: &idx)
        }
        XCTAssertEqual(offsetByNegative3, idx)
        
        
        // index(:_, offsetBy:, limitedBy:)
        let offsetByCountPlusOne = sut.index(sut.startIndex, offsetBy: (sut.count + 1), limitedBy: sut.endIndex)
        XCTAssertNil(offsetByCountPlusOne)
        
        let offsetByNegativeCountPlusOne = sut.index(sut.endIndex, offsetBy: -(sut.count + 1), limitedBy: sut.startIndex)
        XCTAssertNil(offsetByNegativeCountPlusOne)
        
        let limitedByEndIndex = sut.index(sut.startIndex, offsetBy: sut.count, limitedBy: sut.endIndex)
        XCTAssertNotNil(limitedByEndIndex)
        XCTAssertEqual(limitedByEndIndex, sut.index(sut.startIndex, offsetBy: sut.count))
        
        let limitedByStartIndex = sut.index(sut.endIndex, offsetBy: -sut.count, limitedBy: sut.startIndex)
        XCTAssertNotNil(limitedByStartIndex)
        XCTAssertEqual(limitedByStartIndex, sut.index(sut.endIndex, offsetBy: -sut.count))
        
        // distance(from:to:)
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.distance(from: sut.startIndex, to: sut.endIndex), sut.count)
        XCTAssertGreaterThan(sut.distance(from: sut.startIndex, to: sut.endIndex), 0)
        
        XCTAssertGreaterThan(sut.endIndex, sut.startIndex)
        XCTAssertEqual(sut.distance(from: sut.endIndex, to: sut.startIndex), -sut.count)
        XCTAssertLessThan(sut.distance(from: sut.endIndex, to: sut.startIndex), 0)
        
        XCTAssertEqual(sut.distance(from: sut.startIndex, to: sut.startIndex), 0)
        XCTAssertEqual(sut.distance(from: sut.endIndex, to: sut.endIndex), 0)
        
        let midIdx = sut.endIndex / 2
        XCTAssertEqual(sut.distance(from: midIdx, to: sut.index(after: midIdx)), 1)
        XCTAssertEqual(sut.distance(from: midIdx, to: sut.index(before: midIdx)), -1)
    }
    
    // MARK: - subscripts tests
    func testSubscriptIndex() {
        sut = [1, 2, 3, 4, 5]
        XCTAssertEqual(sut[0], sut.first)
        XCTAssertEqual(sut[sut.count - 1], sut.last)
        for idx in 0..<sut.count {
            let expectedValue = sut.storage![idx]
            XCTAssertEqual(sut[idx], expectedValue)
            
            sut[idx] = expectedValue + 10
            XCTAssertEqual(sut[idx], expectedValue + 10)
        }
        
        // value semantics:
        var copy = sut!
        for idx in copy.startIndex..<copy.endIndex {
            copy[idx] -= 10
            XCTAssertNotEqual(sut[idx], copy[idx])
        }
        assertValueSemantics(copy)
    }
    
    func testSubscriptRange() {
        sut = [1, 2, 3, 4, 5]
        
        let slice = sut[1...3]
        for idx in slice.startIndex..<slice.endIndex {
            XCTAssertEqual(slice[idx], sut[idx])
        }
        
        var mutSlice = sut[1...3]
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            mutSlice[idx] += 10
        }
        
        sut[1...3] = mutSlice
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            XCTAssertEqual(sut[idx], mutSlice[idx])
        }
        
        // Value semantics:
        // sut was mutated after first slice was extracted, therefore:
        for idx in slice.startIndex..<slice.endIndex {
            XCTAssertNotEqual(slice[idx], sut[idx])
        }
        XCTAssertFalse(sut.storage === slice.base.storage)
        
        // Let's also check when mutating a slice:
        sut = [1, 2, 3, 4, 5]
        mutSlice = sut[1...3]
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            mutSlice[idx] += 10
        }
        
        for idx in mutSlice.startIndex..<mutSlice.endIndex {
            XCTAssertNotEqual(mutSlice[idx], sut[idx])
        }
        XCTAssertFalse(sut.storage === mutSlice.base.storage)
    }
    
    // MARK: - withContiguousMutableStorageIfAvailable(_:) and withContiguousStorageIfAvailable(_:) tests
    func testWithContiguousMutableStorageIfAvailable() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        let exp1 = expectation(description: "closure completes")
        let result1: Bool? = sut.withContiguousMutableStorageIfAvailable { _ in
            exp1.fulfill()
            
            return true
        }
        wait(for: [exp1], timeout: 1)
        XCTAssertNotNil(result1)
        XCTAssertNil(sut.storage)
        
        sut = [1, 2, 3, 4, 5]
        let expectedResult1 = sut.map { $0 * 10 }
        let exp2 = expectation(description: "closure completes")
        let result2: Bool? = sut.withContiguousMutableStorageIfAvailable { buff in
            for i in buff.startIndex..<buff.endIndex {
                buff[i] *= 10
            }
            exp2.fulfill()
            
            return true
        }
        wait(for: [exp2], timeout: 1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(Array(sut), expectedResult1)
        
        // value semantics:
        var copy = sut!
        let exp3 = expectation(description: "closure completes")
        copy.withContiguousMutableStorageIfAvailable { buffer in
            exp3.fulfill()
            for i in buffer.startIndex..<buffer.endIndex {
                buffer[i] /= 10
            }
        }
        wait(for: [exp3], timeout: 1)
        assertValueSemantics(copy)
        
        // Slice implementation works too:
        sut = RandomQueue(1...10)
        var slice = sut[1...3]
        var sliceBuffElements: Array<Int>!
        let exp4 = expectation(description: "closure completes")
        let result4 = slice.withContiguousMutableStorageIfAvailable { buff -> Bool in
            defer { exp4.fulfill() }
            sliceBuffElements = []
            for i in buff.startIndex..<buff.endIndex {
                buff[i] *= 10
                sliceBuffElements.append(buff[i])
            }
            
            return true
        }
        wait(for: [exp4], timeout: 0.1)
        XCTAssertNotNil(result4)
        XCTAssertEqual(sliceBuffElements, Array(slice))
        
        // value semantics on Slice:
        XCTAssertNotEqual(sut, slice.base)
    }
    
    func testWithContiguousStorageIfAvailable() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        let exp1 = expectation(description: "closure completes")
        let result1: Bool? = sut.withContiguousStorageIfAvailable { _ in
            exp1.fulfill()
            
            return true
        }
        wait(for: [exp1], timeout: 1)
        XCTAssertNotNil(result1)
        XCTAssertNil(sut.storage)
        
        sut = [1, 2, 3, 4, 5]
        let exp2 = expectation(description: "closure completes")
        let rangeToPick = 1...3
        var copiedValues = [Int]()
        let result2: Bool? = sut.withContiguousStorageIfAvailable { buff in
            for i in rangeToPick {
                copiedValues.append(buff[i])
            }
            exp2.fulfill()
            
            return true
        }
        wait(for: [exp2], timeout: 1)
        XCTAssertNotNil(result2)
        XCTAssertEqual(copiedValues, Array(sut[rangeToPick]))
        
        // Slice implementation works too:
        sut = RandomQueue(1...10)
        let slice = sut[1...3]
        var sliceBuffElements: Array<Int>!
        let exp4 = expectation(description: "closure completes")
        let result3 = slice.withContiguousStorageIfAvailable { buff -> Bool in
            defer { exp4.fulfill() }
            sliceBuffElements = Array(buff)
            
            return true
        }
        wait(for: [exp4], timeout: 0.1)
        XCTAssertNotNil(result3)
        XCTAssertEqual(sliceBuffElements, Array(slice))
    }
    
    // MARK: - Functional Programming methods
    func testAllSatisfy() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertTrue(sut.allSatisfy { $0 == 10 })
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertFalse(sut.allSatisfy { $0 == 10 })
        XCTAssertTrue(sut.allSatisfy { $0 <= 5 })
        
        let throwingPred: (Int) throws -> Bool = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(try sut.allSatisfy(throwingPred))
    }
    
    func testForEach() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        var result = [Int]()
        sut.forEach { result.append($0) }
        XCTAssertEqual(result, [])
        
        sut = [1, 2, 3, 4, 5]
        result = []
        sut.forEach { result.append($0 * 10) }
        
        var expectedResult = [Int]()
        sut.storage?.forEach { expectedResult.append($0 * 10) }
        
        XCTAssertEqual(result, expectedResult)
        
        let throwingBody: (Int) throws -> Void = { _ in throw testThrownError }
        XCTAssertThrowsError(try sut.forEach(throwingBody))
    }
    
    func testFilter() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        var result = [Int]()
        result = sut.filter { $0 > 1 }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        let sutContainedElements = Array(sut)
        result = sut.filter { $0 % 2 == 0 }
        XCTAssertEqual(result, sutContainedElements.filter { $0 % 2 == 0 })
        
        let throwingPred: (Int) throws -> Bool = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(try sut.filter(throwingPred))
    }
    
    func testMap() {
        XCTAssertTrue(sut.isEmpty)
        var result: [String] = sut.map { String($0) }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        var expectedResult = [String]()
        sut.forEach { expectedResult.append(String($0)) }
        
        result = sut.map { String($0) }
        XCTAssertEqual(result.count, sut.count)
        XCTAssertEqual(result, expectedResult)
        
        let throwingTransform: (Int) throws -> String = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(result = try sut.map(throwingTransform))
    }
    
    func testFlatMap() {
        XCTAssertTrue(sut.isEmpty)
        var result: [Int] = sut.flatMap {
            return [$0 * 10, $0 * 100, $0 * 1000]
        }
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.flatMap {
            return [$0 * 10, $0 * 100, $0 * 1000]
        }
        var expectedResult: [Int] = []
        for element in sut {
            let iterResult = [element * 10, element * 100, element * 1000]
            expectedResult.append(contentsOf: iterResult)
        }
        XCTAssertEqual(result, expectedResult)
        
        let throwingTransform: (Int) throws -> [Int] = { _ in
            throw testThrownError
        }
        XCTAssertThrowsError(result = try sut.flatMap(throwingTransform))
    }
    
    func testCompactMap() {
        let transform: (Int) -> Int? = { return $0 % 2 == 0 ? $0 : nil }
        XCTAssertTrue(sut.isEmpty)
        var result: [Int] = sut.compactMap(transform)
        XCTAssertTrue(result.isEmpty)
        
        sut = [1, 2, 3, 4, 5]
        let sutContainedElements = sut.map { $0 }
        let expectedResult = sutContainedElements?.compactMap(transform)
        
        result = sut.compactMap { return $0 % 2 == 0 ? $0 : nil }
        XCTAssertEqual(result, expectedResult)
        
        let throwingTransform: (Int) throws -> Int? = { _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(result = try sut.compactMap(throwingTransform))
    }
    
    func testReduce() {
        XCTAssertTrue(sut.isEmpty)
        var result: Int = sut.reduce(0, +)
        XCTAssertEqual(result, 0)
        
        sut = [1, 2, 3, 4, 5]
        result = sut.reduce(0, +)
        XCTAssertEqual(result, 0 + 1 + 2 + 3 + 4 + 5)
        
        let throwingUpdateAccumulatingResult: (Int, Int) throws -> Int = { _, _ in
            throw testThrownError
        }
        
        XCTAssertThrowsError(result = try sut.reduce(0, throwingUpdateAccumulatingResult))
    }
    
    // MARK: - RangeReplaceableCollection tests
    func testReserveCapacity() {
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        sut.reserveCapacity(20)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNotNil(sut.storage)
        XCTAssertGreaterThanOrEqual(sut.capacity, 20)
        
        // when there are already enough free spots to cover it,
        // buffer doesn't get reallocated:
        sut.append(contentsOf: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        let prevResidualCapacity = sut.storage!.residualCapacity
        XCTAssertGreaterThanOrEqual(prevResidualCapacity, 0)
        let prevStorageBaseAddress = sut.storage?
            .withUnsafeBufferPointer { buff in
            
                return buff.baseAddress
            }
        sut.reserveCapacity(prevResidualCapacity)
        XCTAssertTrue(sut.storage?
                        .withUnsafeBufferPointer { buff in
                        
                            return buff.baseAddress
                    } == prevStorageBaseAddress)
        
        // otherwise buffer gets reallocated to a bigger one:
        sut.reserveCapacity(prevResidualCapacity + 1)
        XCTAssertFalse(sut.storage?
                        .withUnsafeBufferPointer { buff in
                        
                            return buff.baseAddress
                    } == prevStorageBaseAddress)
    }
    
    func testReplaceSubrange() {
        // main functionalities guaranteed by CircularBuffer method
        // replace(subrange:with:)
        // Let's test for value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.replaceSubrange(copy.startIndex..., with: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
        assertValueSemantics(copy)
    }
    
    func testAppendElement() {
        // Main functionalities backed by CircularBuffer.
        // We are just gonna check value semantics here:
        var copy = sut!
        copy.append(1)
        assertValueSemantics(copy)
    }
    
    func testAppendContentsOfSequence() {
        // Main functionalities are backed by CircularBuffer.
        // We are gonna test a special case here: when storage
        // is nil and sequence to add contains no elements, then
        // storage is still equal to nil
        XCTAssertNil(sut.storage)
        sut.append(contentsOf: [])
        XCTAssertNil(sut.storage)
        
        // …and test value semantics too:
        var copy = sut!
        copy.append(contentsOf: [1, 2, 3, 4, 5])
        assertValueSemantics(copy)
    }
    
    func testInsertElementAt() {
        // Main functionalities are backed by CircularBuffer.
        // We are going to just test value semantics here:
        
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.insert(0, at: 0)
        assertValueSemantics(copy)
    }
    
    func testInsertContentsOfCollectionAt() {
        // Main functionalities are backed by CircularBuffer,
        // therefore we jsut test a special case here: when storage
        // is empty and collection is empty too, then storage is
        // equal to nil still.
        XCTAssertNil(sut.storage)
        sut.insert(contentsOf: [], at: sut.endIndex)
        XCTAssertNil(sut.storage)
        
        // …and of course we also test value semantics:
        var copy = sut!
        copy.insert(contentsOf: [1, 2, 3, 4, 5], at: copy.endIndex)
        assertValueSemantics(copy)
    }
    
    func testRemoveElementAt() {
        // Main functionalities are backed by CircularBuffer,
        // therefore we just test a special case here: when the
        // removal makes the queue empty, then its storage becomes
        // nil:
        sut = [1]
        let _ = sut.remove(at: sut.startIndex)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // …and of course we also test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.remove(at: 1)
        assertValueSemantics(copy)
    }
    
    func testRemoveSubrange() {
        // Main functionalities are backed by CircularBuffer,
        // therefore we just test a special case here: when
        // subrange includes all elements, then storage becomes nil:
        sut = [1, 2, 3, 4, 5]
        sut.removeSubrange(sut.startIndex..<sut.endIndex)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // …and of course we also test value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeSubrange(copy.startIndex..<copy.index(before: sut.endIndex))
        assertValueSemantics(copy)
    }
    
    func testRemoveFirstElement() {
        let elements = [1, 2, 3]
        sut = RandomQueue(elements)
        let sutContainedElements = sut!.map { $0 }
        
        XCTAssertEqual(sut.removeFirst(), sutContainedElements.first)
        XCTAssertEqual(sut.count, elements.count - 1)
        XCTAssertEqual(Array(sut), Array(sutContainedElements.dropFirst()))
        
        sut = [1]
        let _ = sut.removeFirst()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.removeFirst()
        assertValueSemantics(copy)
    }
    
    func testRemoveFirstKElements() {
        // Main functionalities are backed by CircularBuffer, we
        // just test a special case here: when removal makes the
        // queue instance empty, then storage is nil
        sut = [1, 2, 3, 4, 5]
        sut.removeFirst(5)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // …and value semantics as well:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeFirst(2)
        assertValueSemantics(copy)
    }
    
    func testRemoveAllKeepingCapacity() {
        XCTAssertNil(sut.storage)
        sut.removeAll(keepingCapacity: true)
        XCTAssertNil(sut.storage)
        
        sut = [1, 2, 3, 4, 5]
        sut.removeAll(keepingCapacity: true)
        XCTAssertNotNil(sut.storage)
        
        sut = [1, 2, 3, 4, 5]
        sut.removeAll(keepingCapacity: false)
        XCTAssertNil(sut.storage)
    }
    
    func testPopLast() {
        // Main functionalities are backed by CircularBuffer,
        // here we just test a special case: when becomes empty,
        // then storage is set to nil:
        sut = [1]
        sut.popLast()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // value semantics
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popLast()
        assertValueSemantics(copy)
    }
    
    func testPopFirst() {
        // Main functionalities are backed by CircularBuffer,
        // here we just test a special case: when becomes empty,
        // then storage is set to nil:
        sut = [1]
        sut.popFirst()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // value semantics
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.popFirst()
        assertValueSemantics(copy)
    }
    
    func testRemoveLastElement() {
        let elements = [1, 2, 3]
        sut = RandomQueue(elements)
        let sutContainedElements = sut!.map { $0 }
        
        XCTAssertEqual(sut.removeLast(), sutContainedElements.last)
        XCTAssertEqual(sut.count, elements.count - 1)
        XCTAssertEqual(Array(sut), Array(sutContainedElements.dropLast()))
        
        sut = [1]
        let _ = sut.removeLast()
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // value semantics:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        let _ = copy.removeLast()
        assertValueSemantics(copy)
    }
    
    func testRemoveLastKElements() {
        // Main functionalities are backed by CircularBuffer, we
        // just test a special case here: when removal makes the
        // queue instance empty, then storage is nil
        sut = [1, 2, 3, 4, 5]
        sut.removeLast(5)
        XCTAssertTrue(sut.isEmpty)
        XCTAssertNil(sut.storage)
        
        // …and value semantics as well:
        sut = [1, 2, 3, 4, 5]
        var copy = sut!
        copy.removeLast(2)
        assertValueSemantics(copy)
    }
    
    // MARK: - Equatable and Hasable conformances tests
    func testEquatable() {
        XCTAssertEqual(sut, RandomQueue<Int>())
        
        sut = [1, 2, 3, 4, 5]
        XCTAssertNotEqual(sut, RandomQueue<Int>())
        
        var copy = sut!
        XCTAssertTrue(sut.storage === copy.storage)
        XCTAssertEqual(sut, copy)
        
        copy.append(6)
        XCTAssertNotEqual(sut.count, copy.count)
        XCTAssertNotEqual(sut, copy)
        
        sut.append(6)
        XCTAssertEqual(sut.count, copy.count)
        XCTAssertEqual(sut, copy)
        for idx in 0..<sut.count {
            XCTAssertEqual(sut[idx], copy[idx])
        }
        
        sut[sut.endIndex - 1] = 10
        XCTAssertEqual(sut.count, copy.count)
        XCTAssertNotEqual(sut, copy)
        var indexesWhereDifferent = [Int]()
        for idx in 0..<sut.count where sut[idx] != copy[idx] {
            indexesWhereDifferent.append(idx)
        }
        XCTAssertFalse(indexesWhereDifferent.isEmpty)
    }
    
    func testHashable() {
        var set = Set<RandomQueue<Int>>()
        set.insert(sut)
        XCTAssertTrue(set.contains(sut))
        
        var copy = sut!
        let (inserted, _) = set.insert(copy)
        XCTAssertFalse(inserted)
        
        copy.append(1)
        let afterMutation = set.insert(copy)
        XCTAssertTrue(afterMutation.inserted)
        XCTAssertTrue(afterMutation.memberAfterInsert.storage === copy.storage)
        XCTAssertEqual(afterMutation.memberAfterInsert.hashValue, copy.hashValue)
    }
    
    // MARK: - Codable conformance
    func testEncode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(sut))
    }
    
    func testDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(RandomQueue<Int>.self, from: data))
    }
    
    func testEncodeThanDecode() {
        sut = [1, 2, 3, 4, 5]
        let encoder = JSONEncoder()
        let data = try! encoder.encode(sut)
        
        let decoder = JSONDecoder()
        let decoded = try! decoder.decode(RandomQueue<Int>.self, from: data)
        XCTAssertEqual(decoded, sut)
    }
    
    // MARK: - Custom(Debug)StringConvertible conformance tests
    func testDescription() {
        sut = [1, 2, 3, 4, 5]
        let elementsDescription = Array(sut).description
        XCTAssertEqual(sut.description, "RandomQueue" + elementsDescription)
    }
    
    func testDebugDescription() {
        sut = [1, 2, 3, 4, 5]
        let elementsDescription = Array(sut).description
        XCTAssertEqual(sut.debugDescription, "Optional(RandomQueue.RandomQueue<Swift.Int>(\(elementsDescription)))")
    }
    
    // MARK: - Helpers
    func assertValueSemantics(_ copy: RandomQueue<Int>, file: StaticString = #file, line: UInt = #line) {
        assertAreDifferentValuesAndHaveDifferentStorage(lhs: sut, rhs: copy, file: file, line: line)
    }
    
}


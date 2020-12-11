//
//  Helpers.swift
//  RandomQueueTests
//
//  Created by Valeriano Della Longa on 30/11/2020.
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
import CircularBuffer
@testable import RandomQueue

let testThrownError: NSError = NSError(domain: "com.vdl.RandomQueue", code: 1, userInfo: nil)

protocol EquatableCollectionUsingCircularBuffer: Collection where Element: Equatable {
    var storage: CircularBuffer<Element>? { get }
}

extension RandomQueue: EquatableCollectionUsingCircularBuffer where Element: Comparable {  }

func assertAreDifferentValuesAndHaveDifferentStorage<C: EquatableCollectionUsingCircularBuffer, D: EquatableCollectionUsingCircularBuffer>(lhs: C, rhs: D, file: StaticString = #file, line: UInt = #line) where C.Element == D.Element {
    XCTAssertNotEqual(Array(lhs), Array(rhs), "copy contains same elements of original after mutation", file: file, line: line)
    XCTAssertFalse(lhs.storage === rhs.storage, "copy has same storage instance of original", file: file, line: line)
}



//
//  CircularQueueSlice.swift
//  CircularQueue
//
//  Created by Valeriano Della Longa on 30/11/20.
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

import CircularBuffer

/// A slice of a `RandomQueue` instance.
///
/// The `RandomQueueSlice` type makes it fast and efficient for you to perform
/// operations on sections of a larger queue. Instead of copying over the
/// elements of a slice to new storage, a `RandomQueueSlice` instance presents a
/// view onto the storage of a larger queue. And because `RandomQueueSlice`
/// presents the same interface as `RandomQueue`, you can generally perform the
/// same operations on a slice as you could on the original queue.
///
/// Slices Are Views onto RandomQueues
/// ============================
///
/// For example, suppose you have a queue holding the number of absences
/// from each class during a session.
///
///     let absences: RandomQueue<Int> = [0, 2, 0, 4, 0, 3, 1, 0]
///
/// You want to compare the absences in the first half of the session with
/// those in the second half. To do so, start by creating two slices of the
/// `absences` queue.
///
///     let midpoint = absences.count / 2
///
///     let firstHalf = absences[..<midpoint]
///     let secondHalf = absences[midpoint...]
///
/// Neither the `firstHalf` nor `secondHalf` slices allocate any new storage
/// of their own. Instead, each presents a view onto the storage of the
/// `absences` queue.
///
/// You can call any method on the slices that you might have called on the
/// `absences` queue. To learn which half had more absences, use the
/// `reduce(_:_:)` method to calculate each sum.
///
///     let firstHalfSum = firstHalf.reduce(0, +)
///     let secondHalfSum = secondHalf.reduce(0, +)
///
///     if firstHalfSum > secondHalfSum {
///         print("More absences in the first half.")
///     } else {
///         print("More absences in the second half.")
///     }
///     // Prints "More absences in the first half."
///
/// - Important: Long-term storage of `RandomQueueSlice` instances
///   is discouraged. A slice holds a reference to the entire storage of a larger
///   queue, not just to the portion it presents, even after the original queue's lifetime
///   ends. Long-term storage of a slice may therefore prolong the lifetime of
///   elements that are no longer otherwise accessible, which can appear to be
///   memory and object leakage.
///
/// Slices Maintain Indices
/// =======================
///
/// Unlike `RandomQueue` the starting index for a `RandomQueueSlice`
/// instance isn't always zero.
/// Slices maintain the same indices of the larger queue for the same elements, so the
/// starting index of a slice depends on how it was created, letting you perform
/// index-based operations on either a full queue or a slice.
///
/// Sharing indices between collections and their subsequences is an important
/// part of the design of Swift's collection algorithms. Suppose you are
/// tasked with finding the first two days with absences in the session. To
/// find the indices of the two days in question, follow these steps:
///
/// 1) Call `firstIndex(where:)` to find the index of the first element in the
///    `absences` queue that is greater than zero.
/// 2) Create a slice of the `absences` queue starting after the index found in
///    step 1.
/// 3) Call `firstIndex(where:)` again, this time on the slice created in step
///    2. Where in some languages you might pass a starting index into an
///    `indexOf` method to find the second day, in Swift you perform the same
///    operation on a slice of the original array.
/// 4) Print the results using the indices found in steps 1 and 3 on the
///    original `absences` queue.
///
/// Here's an implementation of those steps:
///
///     if let i = absences.firstIndex(where: { $0 > 0 }) {                 // 1
///         let absencesAfterFirst = absences[(i + 1)...]                   // 2
///         if let j = absencesAfterFirst.firstIndex(where: { $0 > 0 }) {   // 3
///             print("The first day with absences had \(absences[i]).")    // 4
///             print("The second day with absences had \(absences[j]).")
///         }
///     }
///     // Prints "The first day with absences had 2."
///     // Prints "The second day with absences had 4."
///
/// In particular, note that `j`, the index of the second day with absences,
/// was found in a slice of the original queue and then used to access a value
/// in the original `absences` queue itself.
///
/// Slices Inherit Semantics
/// ------------------------
///
/// A slice inherits the value or reference semantics of its base collection.
/// That is, since `RandomQueueSlice` is wrapped around `RandomQueue`
/// which is a mutable collection that has value semantics,
/// hence mutating the original collection would trigger a copy of that collection,
/// and not affect the base collection stored inside of the slice.
///
/// For example, if you update the last element of the `absences` queue from
/// `0` to `2`, the `secondHalf` slice is unchanged.
///
///     absences[7] = 2
///     print(absences)
///     // Prints "[0, 2, 0, 4, 0, 3, 1, 2]"
///     print(secondHalf)
///     // Prints "[0, 3, 1, 0]"
///
/// - Note: To safely reference the starting and ending indices of a slice,
///   always use the `startIndex` and `endIndex` properties instead of
///   specific values.
public struct RandomQueueSlice<Element> {
    public typealias Base = RandomQueue<Element>
    
    #if swift(>=4.1) || (swift(>=3.3) && !swift(>=4.0))
    public typealias _Slice = Slice<Base>
    #else
    public typealias _Slice = RangeReplaceableRandomAccessSlice<Base>
    #endif
    
    private(set) var _slice: _Slice
    
    /// The underlying collection of the slice.
    ///
    /// You can use a slice's `base` property to access its base collection. The
    /// following example declares `singleDigits`, a queue of single digit
    /// integers, and then drops the first element to create a slice of that
    /// queue, `singleNonZeroDigits`.
    /// The `base` property of the slice is equal to `singleDigits`.
    ///
    ///     let singleDigits: RandomQueue<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    ///     let singleNonZeroDigits = singleDigits.dropFirst()
    ///     // singleNonZeroDigits is a
    ///     // RandomQueueSlice<RandomQueue<Int>>
    ///
    ///     print(singleNonZeroDigits.count)
    ///     // Prints "9"
    ///     print(singleNonZeroDigits.base.count)
    ///     // Prints "10"
    ///     print(singleDigits == singleNonZeroDigits.base)
    ///     // Prints "true"
    public private(set) var base: Base {
        get { _slice.base }
        set { _slice = Slice(base: newValue, bounds: bounds) }
    }
    
    public var bounds: Range<Base.Index> {
        _slice.startIndex..<_slice.endIndex
    }
    
    /// Creates a view into the given queue that allows access to elements
    /// within the specified range.
    ///
    /// It is unusual to need to call this method directly. Instead, create a
    /// slice of a queue by using its range-based subscript or by using methods that return
    /// a subsequence.
    ///
    ///     let singleDigits: RandomQueue<Int> = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    ///     let subSequence = singleDigits.dropFirst(5)
    ///     print(Array(subSequence))
    ///     // Prints "[5, 6, 7, 8, 9]"
    ///
    /// In this example, the expression `singleDigits.dropFirst(5))` is
    /// equivalent to calling this initializer with `singleDigits` and a
    /// range covering the last five items of `singleDigits.indices`.
    ///
    /// - Parameters:
    ///   - base: The queue  to create a view into.
    ///   - bounds: The range of indices to allow access to in the new slice.
    public init(base: Base, bounds: Range<Base.Index>) {
        self._slice = Slice(base: base, bounds: bounds)
    }
    
    public init() {
        self._slice = Slice(base: RandomQueue(), bounds: 0..<0)
    }
    
    public init(repeating repeatedValue: Base.Element, count: Int) {
        let base = RandomQueue(repeating: repeatedValue, count: count)
        self._slice = Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }
    
    public init<S>(_ elements: S) where S : Sequence, Self.Element == S.Element {
        let base = RandomQueue(elements)
        self._slice = Slice(base: base, bounds: base.startIndex..<base.endIndex)
    }
    
}

extension RandomQueueSlice: Collection, MutableCollection, BidirectionalCollection, RandomAccessCollection, RangeReplaceableCollection {
    public typealias Index = Base.Index
    
    public typealias Subsequence = Self
    
    public typealias Indices = Slice<Base>.Indices
    
    public typealias Element = Base.Element
    
    public typealias Iterator = Slice<Base>.Iterator
    
    public var startIndex: Base.Index { _slice.startIndex }
    
    public var endIndex: Base.Index { _slice.endIndex }
    
    public var count: Int { _slice.count }
    
    public var isEmpty: Bool { _slice.isEmpty }
    
    public __consuming func makeIterator() -> Slice<Base>.Iterator {
        _slice.makeIterator()
    }
    
    public var indices: Slice<Base>.Indices {
        _slice.indices
    }
    
    public func index(after i: Base.Index) -> Base.Index {
        _slice.index(after: i)
    }
    
    public func formIndex(after i: inout Base.Index) {
        _slice.formIndex(after: &i)
    }
    
    public func index(before i: Base.Index) -> Base.Index {
        _slice.index(before: i)
    }
    
    public func formIndex(before i: inout Base.Index) {
        _slice.formIndex(before: &i)
    }
    
    public func index(_ i: Base.Index, offsetBy distance: Int) -> Base.Index {
        _slice.index(i, offsetBy: distance)
    }
    
    public func index(_ i: Base.Index, offsetBy distance: Int, limitedBy limit: Base.Index) -> Base.Index? {
        _slice.index(i, offsetBy: distance, limitedBy: limit)
    }
    
    public func distance(from start: Base.Index, to end: Base.Index) -> Int {
        _slice.distance(from: start, to: end)
    }
    
    public subscript(position: Base.Index) -> Element {
        get { _slice[position] }
        set { _slice[position] = newValue }
    }
    
    public subscript(otherBounds: Range<Base.Index>) -> Subsequence {
        get { RandomQueueSlice(base: base, bounds: otherBounds) }
        set { replaceSubrange(otherBounds, with: newValue) }
    }
    
    public func withContiguousStorageIfAvailable<R>(_ body: (UnsafeBufferPointer<Base.Element>) throws -> R) rethrows -> R? {
        try base
            .withContiguousStorageIfAvailable { buffer in
                let sliced = UnsafeBufferPointer(rebasing: buffer[bounds])
                
                return try body(sliced)
            }
    }
    
    public mutating func withContiguousMutableStorageIfAvailable<R>(_ body: (inout UnsafeMutableBufferPointer<Base.Element>) throws -> R) rethrows -> R? {
        let bufferBounds = bounds
        var work = RandomQueueSlice()
        (work, self) = (self, work)
        
        defer {
            (work, self) = (self, work)
        }
        
        return try work.base
            .withContiguousMutableStorageIfAvailable { buffer in
                var sliced = UnsafeMutableBufferPointer(rebasing: buffer[bufferBounds])
                let slicedOriginal = sliced
                defer {
                    precondition(
                        sliced.baseAddress == slicedOriginal.baseAddress &&
                            sliced.count == slicedOriginal.count,
                        "RandomQueueSlice withUnsafeMutableBufferPointer: replacing the buffer is not allowed"
                    )
                }
                
                return try body(&sliced)
            }
    }
    
    public mutating func replaceSubrange<C>(_ subrange: Range<Base.Index>, with newElements: C) where C : Collection, Self.Element == C.Element {
        _slice.replaceSubrange(subrange, with: newElements)
    }
    
    public mutating func insert(_ newElement: Base.Element, at i: Base.Index) {
        _slice.insert(newElement, at: i)
    }
    
    public mutating func insert<S>(contentsOf newElements: S, at i: Base.Index) where S : Collection, Self.Element == S.Element {
        _slice.insert(contentsOf: newElements, at: i)
    }
    
    public mutating func remove(at i: Base.Index) -> Base.Element {
        _slice.remove(at: i)
    }
    
    public mutating func removeSubrange(_ bounds: Range<Base.Index>) {
        _slice.removeSubrange(bounds)
    }
    
}


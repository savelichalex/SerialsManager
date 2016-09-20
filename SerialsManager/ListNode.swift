//
//  ListNode.swift
//  SerialsManager
//
//  Created by Alexey Gerasimov on 20/09/16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation

class ListNode<T> {
    var value: T
    var next: ListNode? = nil

    init(_ value: T) {
        self.value = value
    }

    static func arrayToList(arr: [T]) -> ListNode<T>? {
        var root: ListNode<T>? = nil
        var prev: ListNode<T>? = nil
        for el in arr {
            guard root != nil else {
                root = ListNode(el)
                prev = nil
                continue
            }
            let newNode = ListNode(el)
            prev?.next = newNode
            prev = newNode
        }
        return root
    }
}

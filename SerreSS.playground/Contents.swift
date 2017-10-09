//: Playground - noun: a place where people can play

import Foundation

typealias G = Int
let Z = 1

extension G {
    func repeating(_ n: Int) -> [Int] {
        return Array(repeating: self, count: n)
    }
}

extension Optional where Wrapped == G {
    var isZero: Bool {
        return self != nil && self! == 0
    }
    var symbol: String {
        return self.flatMap{ $0 == 1 ? "Z" : "0"} ?? "?"
    }
}

extension Array where Element == String {
    func join(_ separator: String = "") -> String {
        return self.joined(separator: separator)
    }
}

final class Sheet: Sequence {
    final class Component {
        let r: Int
        let p: Int
        let q: Int
        
        var group: G? = nil {
            willSet {
                if group != nil && newValue != nil && group! != newValue! {
                    fatalError("conflict at E_\(r)[\((p, q))], \(group!) != \(newValue!)")
                }
            } didSet {
                update()
            }
        }
        
        weak var sheet: Sheet? = nil
        weak var target: Component? = nil
        weak var cotarget: Component? = nil
        weak var above: Component? = nil
        weak var below: Component? = nil
        
        init(_ r: Int, _ p: Int, _ q: Int) {
            (self.r, self.p, self.q) = (r, p, q)
        }
        
        var isDetermined: Bool {
            return group != nil
        }
        
        var isZero: Bool {
            return group.isZero
        }
        
        var isZeroMap: Bool {
            if self.isZero || target == nil {
                return true
            }
            
            // TODO
            
            return false
        }
        
        var isIsomorphicToAbove: Bool {
            return isZeroMap && (cotarget?.isZeroMap ?? true)
        }
        
        var isInjectiveToTarget: Bool {
            return (above?.isZero ?? false) && (cotarget?.isZeroMap ?? true)
        }
        
        var isSurjectiveToTarget: Bool {
            return (target?.above?.isZero ?? false) && (target?.isZeroMap ?? true)
        }
        
        var isIsomorphicToTarget: Bool {
            return isInjectiveToTarget && isSurjectiveToTarget
        }
        
        func update() {
            if r == 2 {
                let E2 = sheet!
                
                if p == 0 { // copy rows →
                    for p in (1 ..< E2.width) {
                        if E2[0, q].isZero {
                            E2[p, q].group = 0
                        } else if E2[p, 0].isDetermined && E2[0, q].isDetermined {
                            E2[p, q].group = E2[p, 0].group! * E2[0, q].group!
                        }
                    }
                }
                if q == 0 { // copy cols ↑
                    for q in (1 ..< E2.height) {
                        if E2[p, 0].isZero {
                            E2[p, q].group = 0
                        } else if E2[p, 0].isDetermined && E2[0, q].isDetermined {
                            E2[p, q].group = E2[p, 0].group! * E2[0, q].group!
                        }
                    }
                }
            }
            
            if let above = above, !above.isDetermined && isIsomorphicToAbove {
                above.group = self.group
            }
            if let target = target, !target.isDetermined && isIsomorphicToTarget {
                target.group = self.group
            }
            if let cotarget = cotarget, !cotarget.isDetermined && cotarget.isIsomorphicToTarget {
                cotarget.group = self.group
            }
            if let below = below {
                if !below.isDetermined && below.isIsomorphicToAbove {
                    below.group = self.group
                }
                if let target = below.target, below.isIsomorphicToTarget {
                    if !target.isDetermined && below.isDetermined {
                        target.group = below.group
                    }
                    if !below.isDetermined && target.isDetermined {
                        below.group = target.group
                    }
                }
                if let cotarget = below.cotarget, cotarget.isIsomorphicToTarget {
                    if !cotarget.isDetermined && below.isDetermined {
                        cotarget.group = below.group
                    }
                    if !below.isDetermined && cotarget.isDetermined {
                        below.group = cotarget.group
                    }
                }
            }
        }
        
        static func zero(_ r: Int, _ p: Int, _ q: Int) -> Component {
            let c = Component(r, p, q)
            c.group = 0
            return c
        }
    }
    
    let degree: Int
    var elements: [[Component]]
    
    var width: Int {
        return elements.first?.count ?? 0
    }
    
    var height: Int {
        return elements.count
    }
    
    init(_ r: Int, _ width: Int, _ height: Int) {
        self.degree = r
        self.elements = (0 ..< height).map { q in
            (0 ..< width).map { p in
                Component(r, p, q)
            }
        }
        
        for (p, q, e) in self {
            e.sheet = self
            if (0 ..< width).contains(p + r) && (0 ..< height).contains(q - r + 1) {
                let e2 = self[p + r, q - r + 1]
                e.target = e2
                e2.cotarget = e
            }
        }
    }
    
    subscript (p: Int, q: Int) -> Component {
        get {
            if (0 ..< width).contains(p) && (0 ..< height).contains(q) {
                return elements[q][p]
            } else {
                return Component.zero(degree, p, q)
            }
        } set {
            if (0 ..< width).contains(p) && (0 ..< height).contains(q) {
                elements[q][p] = newValue
            }
        }
    }
    
    subscript(t: (Int, Int)) -> Component {
        get {
            return self[t.0, t.1]
        } set {
            self[t.0, t.1] = newValue
        }
    }
    
    var detailDescription : String {
        let head = "\t|\t" + (0 ..< width).map(String.init).joined(separator: "\t")
        let line = String(repeating: "-", count: 4 * (width + 1) + 2)
        let body = elements.enumerated().map { (i: Int, row: [Component]) -> String in
            "\(i)\t|\t" + row.map { $0.group.symbol }.join("\t")
        }
        return ([head, line] + body).reversed().join("\n")
    }
    
    func makeIterator() -> SheetIterator {
        return SheetIterator(self)
    }
    
    struct SheetIterator : IteratorProtocol {
        private let sheet: Sheet
        private var p: (Int, Int)
        
        public init(_ sheet: Sheet) {
            self.sheet = sheet
            self.p = (-1, 0)
        }
        
        mutating public func next() -> (Int, Int, Component)? {
            p = (p.0 + 1, p.1)
            if p.0 >= sheet.width {
                p = (0, p.1 + 1)
            }
            if p.1 >= sheet.height {
                return nil
            }
            return (p.0, p.1, sheet[p.0, p.1])
        }
    }
}

final class SerreSS {
    var name: String? = nil
    let size: (width: Int, height: Int)
    
    var width : Int { return size.width }
    var height: Int { return size.height }
    
    var sheets: [Sheet] = []
    var total: [G?] = []

    subscript (i: Int) -> Sheet {
        get {
            return sheets[i - 2]
        } set {
            sheets[i - 2] = newValue
        }
    }
    
    var fiber: [G?] {
        get {
            let E2 = self[2]
            return (0 ..< height).map { q in E2[0, q].group }
        } set {
            let E2 = self[2]
            newValue.enumerated().forEach{ (i, g) in E2[0, i].group = g }
        }
    }
    
    var base: [G?] {
        get {
            let E2 = self[2]
            return (0 ..< width).map { p in E2[p, 0].group }
        } set {
            let E2 = self[2]
            newValue.enumerated().forEach{ (i, g) in E2[i, 0].group = g }
        }
    }
    
    var lastSheet: Sheet {
        return sheets.last!
    }
    
    var maxDegree: Int {
        return sheets.count + 1
    }
    
    init(size: (width: Int, height: Int)) {
        assert(size.width > 0 && size.height > 0)
        
        self.size = size
        
        let count = min(size.width - 1, size.height)
        self.sheets = (2 ..< 2 + count).map{ r in Sheet(r, width, height) }
        
        for r in (2 ..< 2 + count - 1) {
            let E1 = self[r]
            let E2 = self[r + 1]
            for (p, q, _) in E1 {
                let (e1, e2) = (E1[p, q], E2[p, q])
                e1.above = e2
                e2.below = e1
            }
        }
    }
    
    var detailDescription : String {
        return sheets.map{
            "E_\( $0.degree < maxDegree ? "\($0.degree)" : "∞")\n"
                + $0.detailDescription
            }.join("\n\n")
    }
    
    func solve() {
        fillEinf()
    }
    
    func fillE2() {
        let E2 = self[2]
        for p in (1 ..< width) {
            for q in (1 ..< height) {
                if E2[p, q].group != nil {
                    continue
                }
                
                if E2[p, 0].isZero {
                    E2[p, q].group = 0
                } else if E2[0, q].isZero {
                    E2[p, q].group = 0
                } else if E2[p, 0].isDetermined && E2[0, q].isDetermined {
                    E2[p, q].group = E2[p, 0].group! * E2[0, q].group!
                }
            }
        }
    }

    func fillEinf() {
        let Einf = self.lastSheet
        for (r, g) in total.enumerated() {
            if !g.isZero {
                continue
            }
            
            for p in (0 ... r) {
                let q = r - p
                Einf[p, q].group = 0
            }
        }
    }
}

var E = SerreSS(size: (5, 2))

E.name = "S^1 -> S^5 -> CP^2"
E.fiber = [Z, Z]
E.total = [Z, 0, 0, 0, 0, Z]
E.solve()

print(E.name!, "\n")
print(E.detailDescription, "\n")
print("H^*(CP^2) = {", E.base.flatMap{ $0 == 1 ? "Z" : "0"}.join(", "), "}")

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
        weak var sheet: Sheet!
        
        let r: Int
        let p: Int
        let q: Int
        
        init(_ sheet: Sheet, _ r: Int, _ p: Int, _ q: Int, group: G? = nil) {
            self.sheet = sheet
            (self.r, self.p, self.q) = (r, p, q)
            self.group = group
        }
        
        var group: G? = nil {
            willSet {
                if group != nil && newValue != nil && group! != newValue! {
                    fatalError("conflict at E_\(r)[\((p, q))], \(group!) != \(newValue!)")
                }
            } didSet {
                update(didSet: true)
            }
        }
        
        var target: Component {
            return sheet[p + r, q - r + 1]
        }
        
        var cotarget: Component {
            return sheet[p - r, q + r - 1]
        }
        
        var above: Component? {
            return sheet.above?[p, q]
        }
        
        var below: Component? {
            return sheet.below?[p, q]
        }
        
        var isDetermined: Bool {
            return group != nil
        }
        
        var isZero: Bool {
            return group.isZero
        }
        
        var isZeroMap: Bool {
            if self.isZero || target.isZero {
                return true
            }
            
            // TODO
            
            return false
        }
        
        var isIsomorphicToAbove: Bool {
            return isZeroMap && cotarget.isZeroMap
        }
        
        var isInjectiveToTarget: Bool {
            return self.isZero || ((above?.isZero ?? false) && cotarget.isZeroMap)
        }
        
        var isSurjectiveToTarget: Bool {
            return target.isZero || ((target.above?.isZero ?? false) && target.isZeroMap)
        }
        
        var isIsomorphicToTarget: Bool {
            return isInjectiveToTarget && isSurjectiveToTarget
        }
        
        func update(didSet: Bool = false) {
            guard (0 ..< sheet.width).contains(p) && (0 ..< sheet.height).contains(q) else {
                return
            }
            
            if didSet && r == 2 {
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
            
            if self.isDetermined {
                if let above = above, !above.isDetermined && isIsomorphicToAbove {
                    above.group = self.group
                }
                
                if self.isIsomorphicToTarget && !target.isDetermined {
                    target.group = self.group
                }
                
                if cotarget.isIsomorphicToTarget && !cotarget.isDetermined {
                    cotarget.group = self.group
                }
                
                if let below = below, !below.isDetermined && below.isIsomorphicToAbove {
                    below.group = self.group
                }
            }
            
            if didSet {
                target.update()
                cotarget.update()
                below?.update()
                below?.target.update()
                below?.cotarget.update()
            }
        }
    }
    
    let degree: Int
    var elements: [[Component]] = []
    
    var width: Int {
        return elements.first?.count ?? 0
    }
    
    var height: Int {
        return elements.count
    }
    
    var above: Sheet?
    var below: Sheet?
    
    var upperBounded = true
    var rightBounded = true
    
    init(_ r: Int, _ width: Int, _ height: Int) {
        self.degree = r
        self.elements = (0 ..< height).map { q in
            (0 ..< width).map { p in
                Component(self, r, p, q)
            }
        }
    }
    
    subscript (p: Int, q: Int) -> Component {
        get {
            if (0 ..< width).contains(p) && (0 ..< height).contains(q) {
                return elements[q][p]
            } else if (p < 0 || q < 0) || (p >= width && q < height && rightBounded) || (p < width && q >= height && upperBounded) || (p >= width && q >= height && rightBounded && upperBounded) {
                return Component(self, degree, p, q, group: 0)
            } else {
                return Component(self, degree, p, q)
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
    
    var lastSheet: Sheet {
        return sheets.last!
    }
    
    var maxDegree: Int {
        return sheets.count + 1
    }
    

    var rightBounded = true {
        didSet {
            sheets.forEach{ $0.rightBounded = rightBounded }
        }
    }

    var upperBounded = true {
        didSet {
            sheets.forEach{ $0.upperBounded = upperBounded }
        }
    }
    
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
    
    var total: [G?] = [] {
        didSet {
            let Einf = self.lastSheet
            for (r, g) in total.enumerated() {
                if !g.isZero {
                    continue
                }
                
                for p in (0 ... r) {
                    let q = r - p
                    if p < width && q < height {
                        Einf[p, q].group = 0
                    }
                }
            }
        }
    }
    
    init(size: (width: Int, height: Int)) {
        assert(size.width > 0 && size.height > 0)
        
        self.size = size
        
        let count = min(size.width - 1, size.height)
        self.sheets = (2 ..< 2 + count).map{ r in Sheet(r, width, height) }
        
        for r in (2 ..< 2 + count - 1) {
            let E1 = self[r]
            let E2 = self[r + 1]
            E1.above = E2
            E2.below = E1
        }
    }
    
    var detailDescription : String {
        return sheets.map{
            "E_\( $0.degree < maxDegree ? "\($0.degree)" : "∞")\n"
                + $0.detailDescription
            }.join("\n\n")
    }
}

do {
    let n = 3
    let E = SerreSS(size: (2 * n + 1, 2))
    
    E.name = "S^1 -> S^\(2*n+1) -> CP^\(n)"
    E.fiber = [Z, Z]
    E.total = [Z] + 0.repeating(2 * n) + [Z]
    
    print(E.name!, "\n")
    print(E.detailDescription, "\n")
    print("H^*(CP^\(n)) = {", E.base.map{ $0.symbol }.join(", "), "}\n\n")
}

do {
    let n = 3
    let E = SerreSS(size: (n+1, 10))
    
    E.name = "LS^\(n) -> PS^\(n) -> S^\(n)"
    E.upperBounded = false
    E.base = [Z] + 0.repeating(n-1) + [Z]
    E.total = [Z] + 0.repeating(11)
    
    print(E.name!, "\n")
    print(E.detailDescription, "\n")
    
    E[2][3, 6].isZeroMap
    print("H^*(LP^\(n)) = {", E.fiber.map{ $0.symbol }.join(", "), "}\n\n")
}

do {
    let n = 2
    let E = SerreSS(size: (2*n + 2, n*n + 1))
    
    E.name = "U(\(n)) -> U(\(n+1)) -> S^\(2*n+1)"
    E.fiber = [Z, Z, 0, Z, Z]
    E.base  = [Z] + 0.repeating(2 * n) + [Z]
    
    print(E.name!, "\n")
    print(E.detailDescription, "\n")
    print("H^*(U(\(n+1))) = {", E.total.map{ $0.symbol }.join(", "), "}\n\n")
    
    // TODO compute total from E_infty
}

do {
    let n = 2
    let E = SerreSS(size: (8, 6))
    
    E.name = "K(Z, \(n)) -> pt -> K(Z, \(n+1))"
    E.rightBounded = false
    E.upperBounded = false
    E.fiber = [Z, 0, Z, 0, Z, 0, Z, 0]
    E.total = [Z] + 0.repeating(16)

    print(E.name!, "\n")
    print(E.detailDescription, "\n")
    print("H^*(Z, (\(n+1))) = {", E.base.map{ $0.symbol }.join(", "), "}\n\n")
}

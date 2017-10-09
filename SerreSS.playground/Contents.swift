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
    let degree: Int
    var elements: [[G?]]
    
    var width: Int {
        return elements.first?.count ?? 0
    }
    
    var height: Int {
        return elements.count
    }
    
    init(_ degree: Int, _ width: Int, _ height: Int) {
        self.degree = degree
        self.elements = Array(repeating: Array(repeating:G?.none , count: width), count: height)
    }
    
    subscript (p: Int, q: Int) -> G? {
        get {
            if (0 ..< width).contains(p) && (0 ..< height).contains(q) {
                return elements[q][p]
            } else {
                return 0
            }
        } set {
            if (0 ..< width).contains(p) && (0 ..< height).contains(q) {
                elements[q][p] = newValue
            }
        }
    }
    
    subscript(t: (Int, Int)) -> G? {
        get {
            return self[t.0, t.1]
        } set {
            self[t.0, t.1] = newValue
        }
    }
    
    func row(_ p: Int) -> [G?] {
        return (0 ..< width).map{ self[p, $0] }
    }
    
    func col(_ q: Int) -> [G?] {
        return (0 ..< height).map{ self[$0, q] }
    }
    
    func target(_ p: Int, _ q: Int) -> (Int, Int) {
        let r = degree
        return (p + r, q - r + 1)
    }
    
    func cotarget(_ p: Int, _ q: Int) -> (Int, Int) {
        let r = degree
        return (p - r, q + r - 1)
    }
    
    func isZeroMap(_ p: Int, _ q: Int) -> Bool {
        if self[p, q].isZero || self[target(p, q)].isZero {
            return true
        }
        
        return false // false meaning 'unknown'
    }
    
    func isZeroMap(_ e: (Int, Int)) -> Bool {
        return isZeroMap(e.0, e.1)
    }
    
    var detailDescription : String {
        let head = "\t|\t" + (0 ..< width).map(String.init).joined(separator: "\t")
        let line = String(repeating: "-", count: 4 * (width + 1) + 2)
        let body = elements.enumerated().map { (i: Int, row: [G?]) -> String in
            "\(i)\t|\t" + row.map { $0.symbol }.join("\t")
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
        
        mutating public func next() -> (Int, Int, G?)? {
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

final class SpectralSequence {
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
            return self[2].col(0)
        } set {
            let E2 = self[2]
            newValue.enumerated().forEach{ (i, g) in E2[0, i] = g }
        }
    }
    
    var base: [G?] {
        get {
            return self[2].row(0)
        } set {
            let E2 = self[2]
            newValue.enumerated().forEach{ (i, g) in E2[i, 0] = g }
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
    }
    
    var detailDescription : String {
        return sheets.map{
            "E_\( $0.degree < maxDegree ? "\($0.degree)" : "∞")\n"
                + $0.detailDescription
            }.join("\n\n")
    }
    
    func solve() {
        fillE2()
        cascadeZeros()
        fillEinf()
        updateAll()
    }
    
    func fillE2() {
        let E2 = self[2]
        for p in (0 ..< width) {
            for q in (0 ..< height) {
                if E2[p, q] != nil {
                    continue
                }
                
                if E2[p, 0].isZero {
                    E2[p, q] = 0
                } else if E2[0, q].isZero {
                    E2[p, q] = 0
                } else if E2[p, 0] != nil && E2[0, q] != nil {
                    E2[p, q] = E2[p, 0]! * E2[0, q]!
                }
            }
        }
    }

    func cascadeZeros() {
        let N = maxDegree
        if N == 2 {
            return
        }
        
        for (p, q, g) in self[2] {
            if g.isZero {
                for r in (3 ... N) {
                    let Er = self[r]
                    Er[p, q] = 0
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
                Einf[p, q] = 0
            }
        }
    }
    
    func updateAll() {
        let E2 = self[2]
        for (p, q, _) in E2 {
            update(2, p, q)
        }
    }
    
    func update(_ r: Int, _ p: Int, _ q: Int) {
        let Er = self[r]
        let infty = maxDegree
        
        guard (0 ..< width).contains(p) && (0 ..< height).contains(q) && (2 ... infty).contains(r) else {
            return
        }
        
        guard r < infty else {
            return
        }
        
        let Er1 = self[r + 1]
        
        if Er.isZeroMap(p, q) && Er.isZeroMap(Er.cotarget(p, q)) { // => E_r[p, q] = E_{r+1}[p, q]
            if Er[p, q] == nil {
                
                if Er1[p, q] == nil {
                    update(r + 1, p, q)
                }
                
                if Er1[p, q] != nil {
                    Er[p, q] = Er1[p, q]!
                    // update?
                    
                    // if r == 2 && ...
                }
            } else {
                if Er1[p, q] == nil {
                    Er1[p, q] = Er[p, q]!
                    update(r + 1, p, q)
                } else if Er[p, q] != Er1[p, q] {
                    fatalError()
                }
            }
        }
        
        else if Er1[p, q].isZero {
            
        }
    }
}

let n = 2
var E = SpectralSequence(size: (2 * n + 1, 2))

E.name = "S^1 -> S^{2n + 1} -> CP^n"
E.fiber = [Z, Z]
E.total = [Z] + 0.repeating(2 * n) + [Z]

E.solve()

print(E.detailDescription)

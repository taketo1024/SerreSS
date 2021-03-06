# SerreSS

```swift
let E = SerreSS(size: (5, 2))

E.name = "S^1 -> S^5 -> CP^2"
E.fiber = [Z, Z]                 // the cohomology groups of S^1
E.total = [Z, 0, 0, 0, 0, Z]     // the cohomology groups of S^5

print(E.name!, "\n")
print(E.detailDescription, "\n")
print("H^*(CP^2) = ", E.base ) // the cohomology groups of CP^2 computed by SerreSS
```

```
S^1 -> S^5 -> CP^2 

E_2
1 | Z 0 Z 0 Z
0 | Z 0 Z 0 Z
--------------
  | 0 1 2 3 4

E_∞
1 | 0 0 0 0 Z
0 | Z 0 0 0 0
--------------
  | 0 1 2 3 4 

H^*(CP^2) = [ Z, 0, Z, 0, Z ]
```

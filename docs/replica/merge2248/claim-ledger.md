# Merge 2248 claim ledger

| Claim | Kind | Confidence | Product consequence |
|---|---|---:|---|
| The game is Number Connect, not four-direction 2048 | fact | high | Dedicated path-selection model replaces the prior 2048 reuse |
| Board width is 5; difficulty row counts are 8/7/6/5 | measured serialization | high | Default board is 5×8 |
| A path may move in all eight neighboring directions | fact | high | Orthogonal and diagonal adjacency are accepted |
| The first two values must match | fact | high | Second selection is equality-gated |
| Later values may equal the previous value or double it | fact | high | Every later selection uses that local rule |
| The released chain becomes a power-of-two result | observed rule family | medium | The implementation rounds the chain sum upward to a power of two |
| The reference palette begins red, violet, yellow, green, blue | measured serialization | high | Tile colors use independently specified matching RGB values |
| The standard win target is 2048 | measured serialization | high | Creating a 2048 tile ends the round as a win |
| Fall timing is 0.16 seconds per square | measured serialization | high | Reserved for the next animation-polish pass; current model settles immediately |

“Medium” rows identify the remaining hypothesis explicitly; they are not treated
as extracted source truth.

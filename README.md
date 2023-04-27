Used Imports
============

## Quick start

Install:
```
raco pkg install 
```

Use with one file:
```
raco used-imports racket/string
```
Or with multiple files:
```
raco used-imports racket/string racket/list *.rkt
```


For example, suppose the file "mod1.rkt" contains:
```racket
 #lang racket/base
 (require racket/string
          racket/format)
 (string-split "abc def")
 (~a 'abc)
```
 Then `raco used-imports mod1.rkt` displays
```
racket/base
  quote
  require
racket/format
  ~a
racket/string
  string-split
```
An API is also available. See the [docs](https://docs.racket-lang.org/used-imports/index.html).

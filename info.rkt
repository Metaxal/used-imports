#lang info
(define collection "used-imports")
(define deps '("define2"
               "drracket-tool-text-lib"
               "base"))
(define build-deps '("sandbox-lib"
                     "scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/used-imports.scrbl" ())))
(define pkg-desc "What bindings come from which imported module?")
(define version "0.1")
(define pkg-authors '(lorseau))
(define license '(Apache-2.0 OR MIT))
(define raco-commands
  '(("used-imports" (submod used-imports main) "displays used imported bindings and their origin" #f)
    ("multi-used-imports"
     (submod used-imports multi-used-imports)
     "displays used import bindings by module of origin"
     #f)))

#lang info
(define collection "used-imports")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/used-imports.scrbl" ())))
(define pkg-desc "Description Here")
(define version "0.0")
(define pkg-authors '(lorseau))
(define license '(Apache-2.0 OR MIT))
(define raco-commands
  '(("used-imports" (submod used-imports main) "displays used imported bindings and their origin" #f)
    ("multi-used-imports"
     (submod used-imports multi-used-imports)
     "displays used import bindings by module of origin"
     #f)))

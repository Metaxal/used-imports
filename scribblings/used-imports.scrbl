#lang scribble/manual
@require[@for-label[used-imports
                    racket/base]
         racket/sandbox
         scribble/example]

@title{Used Imports}
@author{Laurent Orseau}

This packages defines the two raco commands @tt{raco used-imports} and
@tt{raco multi-used-imports}
The API is also described below.


@defmodule[used-imports]

Quick start:
After installing, try on the command line: @verbatim{raco used-imports syntax/parse}


@defproc[(module->used-imports [mod module-path?])
         hash?]{

 Returns a dictionary of symbols per imported module, where each symbol is used at least once
 in the module @racket[mod].

Suppose that file "mod1.rkt" contains the following code:
 @codeblock|{
 #lang racket/base
 (require racket/string
          racket/format)
 (string-split "abc def")
 (~a 'abc)
 }|
 Then @racket[(module->used-imports "mod1.rkt")] returns:
 @racketblock[
 (hash 'racket/base
       (set 'require 'quote)
       
       'racket/format
       (set '~a)
       
       'racket/string
       (set 'string-split))]
 
Another example:
 @racketblock[
 (module->used-imports 'syntax/parse)
 (code:comment "evaluates to:")
 (hash
  'racket/base
  (set 'syntax? 'for-syntax 'except-out 'identifier? 'symbol?
       'require 'provide 'string? 'begin-for-syntax)
  
  'racket/contract/base
  (set 'or/c 'struct-type-property/c 'any/c 'contract-out '->)
  
  'syntax/parse/private/pattern-expander
  (set 'pattern-expander)
  
  'syntax/parse/private/residual-ct
  (set
   'syntax-local-syntax-parse-pattern-introduce
   'prop:pattern-expander
   'prop:syntax-class
   'pattern-expander?)
  
  "parse/experimental/contract.rkt"
  (set 'expr/c)
  
  "parse/experimental/provide.rkt"
  (set 'provide-syntax-class/contract))]
 
}

@defproc[(multi-used-imports [mods (listof module-path?)]
                             [#:verbose? verbose? boolean? #f])
         hash?]{
For a list of modules (in the form of a file path or a module symbol like @racket['racket/string]),
 returns a dictionary of dictionaries.
 The top level key is a module name that is imported by any of the modules @racket[mods] (say, module A).
 The second level key is a module of @racket[mods] (say, module B), and the values are the bindings (symbols)
 used in module B by module A.

 If @racket[verbose?] is true, information is displayed during the parsing of the files.
 The parsing (via check-syntax) can take a while, so it is useful to know if progress is being made.
 

 Suppose that file "mod1.rkt" contains the following code:
 @codeblock|{
 #lang racket/base
 (require racket/string
          racket/format)
 (string-split "abc def")
 (~a 'abc)
 }|
 and that file "mod2.rkt" contains:
 @codeblock|{
 #lang racket/base
 (require racket/string
          racket/list)
 (string-split "abc def")
 (first '(a b c))
 }|

 Then
 @racket[(multi-used-imports '("mod1.rkt" "mod2.rkt"))] evaluates to
 @racketblock[
 (hash
 'racket/base
 (list (cons "mod2.rkt" (set 'require 'quote)) (cons "mod1.rkt" (set 'require 'quote)))
 'racket/format
 (list (cons "mod1.rkt" (set '~a)))
 'racket/list
 (list (cons "mod2.rkt" (set 'first)))
 'racket/string
 (list (cons "mod2.rkt" (set 'string-split)) (cons "mod1.rkt" (set 'string-split))))]
 
 The command
 @verbatim{raco multi-used-imports *.rkt}
 has the same effect, but the result
 is displayed in a more readable format.
}




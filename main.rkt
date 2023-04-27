#lang racket/base
(require setup/path-to-relative
         drracket/check-syntax
         syntax/modresolve
         racket/match
         racket/list
         racket/port
         racket/dict
         racket/set
         define2)

(provide module->used-imports
         multi-used-imports)

(read-accept-lang #t)
(read-accept-reader #t)


;; Copied from the racket docs on `show-content`
(define (make-paths-be-module-paths x)
    (let loop ([x x])
      (cond
        [(pair? x) (cons (loop (car x)) (loop (cdr x)))]
        [(vector? x) (for/vector ([x (in-vector x)])
                       (loop x))]
        [(path? x) (path->relative-string/library x)]
        [else x])))

;; TODO: flag to allow for using resolved path so that symbolic modules and modules
;; referred in a relative way are known to be the same.
;; Needs to keep the relative directories.

;; mod : (or/c path-string? symbol?)
(define (module->used-imports mod)
  (define mod-path (if (symbol? mod)
                       (resolve-module-path mod)
                       mod))
  (define synt (read-syntax mod-path (open-input-file mod-path)))

  ;; Collect the hash of (position . element)
  (define syms (make-hash))
  (let loop ([s synt])
    (define l (syntax-e s))
    (cond [(list? l)
           (for-each loop l)]
          [else
           (hash-set! syms
                      (+ -1 (syntax-position s)) ; there's an offset between syntax position and syncheck (drracket)
                      (list l (syntax-position s) (+ (syntax-position s) (syntax-span s))))]))

  (define content (make-paths-be-module-paths (show-content synt)))

  ;; Collect the hash of (import-module . (set-of used-elements))
  (define h (make-hash))
  (for ([ann (in-list content)])
    (match ann
      [(vector syncheck:add-mouse-over-status start end (pregexp #px"imported from (.*)"
                                                                 (list _ req)))
       (define obj (first (hash-ref syms start '(#f))))
       (when (and obj (symbol? obj))
         (hash-update! h
                     (with-input-from-string req read)
                     (λ (s) (set-add s obj)
                       #;(set-add s (hash-ref syms start (list start end #f))))
                     (set)))]
      [else #f]))
  h)

;; Returns a hash of (module1 . (module2 . bindings))
;; where module1's bindings are used by module2,
;; and module2 is one of mods.
;; mods : (list-of (or/c string-path? symbol?))
;; If augment hash is specificied, it is augmented by the result and is the return value.
(define (multi-used-imports mods #:? [verbose? #f])
  (define top-h (make-hash))
  (when verbose? (displayln "Parsing files..."))
  (for ([mod1 (in-list mods)])
    (when verbose? (displayln mod1))
    (with-handlers ([exn:fail? (λ (e)
                                 (eprintf (exn-message e))
                                 (eprintf "\nSkipping.\n"))])
      (define h (module->used-imports mod1))
      (for ([(mod2 used-imports) (in-hash h)])
        (hash-update! top-h
                      mod2
                      (λ (l) (cons (cons mod1 used-imports)
                                   l))
                      '()))))
  (when verbose? (displayln "Done.\n"))
  top-h)

(define (raco-used-imports mod-str)
  (define mod
    (if (file-exists? mod-str)
      mod-str
      (resolve-module-path (string->symbol mod-str)))) ; exists with informative error if fails
  (define h (module->used-imports mod))
  (define pairs
    (sort (map (λ (p) (cons (format "~a" (car p)) (cdr p)))
               (hash->list h))
          string<=?
          #:key car))
  (for ([(req-mod syms) (in-dict pairs)])
    (displayln req-mod)
    (define str-syms (sort (map (λ (x) (format "  ~a" x)) (set->list syms)) string<=?))
    (for-each displayln str-syms)))

(define (raco-multi-used-imports mod-strs)
  (define mods
    (for/list ([mod-str (in-list mod-strs)])
      (if (file-exists? mod-str)
        mod-str
        (resolve-module-path (string->symbol mod-str)))))  ; exists with informative error if fails
  (define h (multi-used-imports mods #:verbose? #t))
  (define d
    (sort (map (λ (p) (cons (format "~a" (car p)) (cdr p)))
               (hash->list h))
          string<=?
          #:key car))
  (for ([(req-mod d2) (in-dict d)])
    (displayln req-mod)
    (displayln " is required by:")
    (define pairs (sort (map (λ (p) (cons (format "~a" (car p)) (cdr p)))
                             d2)
                        string<=?
                        #:key car))
    (for ([(req-mod syms) (in-dict pairs)])
      (printf "  ~a\n" req-mod)
      (define str-syms (sort (map (λ (x) (format "    ~a" x)) (set->list syms)) string<=?))
      (for-each displayln str-syms))))

(module+ main
  (define args (vector->list (current-command-line-arguments)))
  (cond
    [(or (empty? args) (member (first args) '("-h" "--help")))
     (displayln "Takes a list of files or module names, like \"my-file.rkt\" or \"racket/string\".")
     (displayln "The list of imports used by the module is displayed, grouped by module of origin.")]
    [(= 1 (length args))
     (raco-used-imports (first args))]
    [else
     (raco-multi-used-imports args)]))


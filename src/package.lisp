(defpackage :dhs-sequences
  (:use :cl)
  (:documentation "Container library")
  (:export #:queue-push
           #:empty-p
           #:sequence-empty
           #:queue-pop
           #:queue-pop-wait
           #:make-blocking-queue
           #:atomic/value
           #:make-atomic-variable
           #:atomic-variable
           #:with-atomic-variable
           #:hash-map
           #:make-hash-map
           #:hash-get
           #:make-blocking-hash-map
           #:blocking-hash-map
           #:with-hash-get-or-update
           #:hash-get-or-update
           #:blocking-queue
           #:with-disabled-interrupts
           #:queue-start-workers
           #:queue-job
           #:task-queue
           #:with-locked-instance
           #:hash-iterator
           #:hash-remove
           #:cas
           #:make-cas-wrapper
           #:cas-wrapper/value
           #:cas-wrapper
           #:content-length
           #:make-queue
           #:call-with-cas
           #:with-cas-update
           #:queue
           #:hash-keys
           #:delete-all
           #:container
           #:tree-insert
           #:tree-find-node
           #:tree-delete-node
           #:tree-delete-element
           #:tree-first-node
           #:tree-first-element
           #:node-element
           #:tree-previous
           #:tree-next
           #:tree-find-element))

(defpackage :dhs-sequences.red-black-tree
    (:use :cl :dhs-sequences)
    (:export
     #:red-black-tree))

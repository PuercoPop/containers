(in-package :dhs-sequence-tests)

(declaim (optimize (safety 3) (speed 0) (debug 3)))

(defun make-value-producer ()
  (let ((i 0))
    (lambda ()
      (format nil "~r" (incf i)))))

(defun make-values-list (n)
  (loop
     with p = (make-value-producer)
     repeat n
     collect (funcall p)))

(defun tree-elements (q)
  (loop
     for x = (dhs-sequences.red-black-tree::tree-first-node q) then (dhs-sequences.red-black-tree::tree-successor q x)
     until (eq x (dhs-sequences.red-black-tree::red-black-tree/empty-node q))
     collect (dhs-sequences.red-black-tree::node/value x)))

(defun test-insert-n-elements (n)
  (let ((values (make-values-list n))
        (q (make-instance 'dhs-sequences.red-black-tree:red-black-tree)))
    (dolist (v values)
      (dhs-sequences.red-black-tree::tree-insert q v))
    (let ((sorted (sort values #'string<))
          (from-tree (tree-elements q)))
      (fiveam:is (equal sorted from-tree)))))

(fiveam:test rbtree-insert-elements-test
  (loop
     for i in '(1 2 3 4 5 6 7 8 9 10 100 1000 5000 10000)
     do (test-insert-n-elements i)))

(defun test-remove (n)
  (let ((values (make-values-list n))
        (q (make-instance 'dhs-sequences.red-black-tree:red-black-tree)))
    (dolist (v values)
      (dhs-sequences.red-black-tree::tree-insert q v))
    (let ((sorted (sort values #'string<)))
      (fiveam:is (equal sorted (tree-elements q)))
      (loop
         with z = sorted
         for x in values
         do (let ((node (dhs-sequences.red-black-tree::exact-query q x)))
              (fiveam:is (not (null node)))
              (dhs-sequences.red-black-tree::tree-delete-node q node)
              (setf z (remove x z :test #'string=))
              (fiveam:is (equal z (tree-elements q))))))))

(fiveam:test rbtree-remove-element-test
  (loop
     for i in '(1 2 3 4 5 6 7 8 9 10 100 1000 5000 10000)
     do (test-remove i)))

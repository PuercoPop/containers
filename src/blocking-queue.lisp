(in-package :containers)

(defclass generic-sequence ()
  ()
  (:documentation "Generic ordered sequence"))

(defgeneric seq-empty-p (seq)
  (:documentation "Return non-nil if SEQ is empty."))

(define-condition sequence-empty (error)
  ()
  (:documentation "Error that is raised if an attempt is made to
access pop an element from an empty sequence."))

(defclass queue (generic-sequence)
  ((content :type (vector t *)
            :initform (make-array 10 :adjustable t)
            :accessor queue/content)
   (head    :type (integer 0)
            :initform 0
            :accessor queue/head)
   (tail    :type (integer 0)
            :initform 0
            :accessor queue/tail))
  (:documentation "Queue that supports insertion and removal from both the tail and head"))

(defmethod print-object ((obj queue) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (with-slots (content head tail) obj
      (format stream "SIZE ~a" (mod (- tail head) (array-dimension content 0))))))

(defmethod seq-empty-p ((queue queue))
  (with-slots (head tail) queue
    (= head tail)))

(defun make-queue ()
  "Create a new instance of a queue."
  (make-instance 'queue))

(defgeneric queue-push (queue element)
  (:documentation "Push ELEMENT to the tail of QUEUE"))

(defgeneric queue-pop (queue &key if-empty)
  (:documentation "Pop the element from the head of QUEUE"))

(defmethod queue-push ((queue queue) element)
  (with-slots (content head tail) queue
    (let ((size (array-dimension content 0)))
      (when (= (mod (- tail head) size) (1- size))
        (adjust-array content (* size 2))
        (when (< tail head)
          (loop
             for src from tail below head
             for dest from (1+ head)
             do (setf (aref content tail) dest))
          (setq tail (+ tail size))))
      (setf (aref content tail) element)
      (setq tail (mod (1+ tail) (array-dimension content 0)))
      element)))

(defmethod queue-pop ((queue queue) &key (if-empty nil if-empty-set-p))
  (with-slots (content head tail) queue
    (if (= head tail)
        (if if-empty-set-p
          if-empty
          (error 'sequence-empty))
        (let ((result (aref content head)))
          (setq head (mod (1+ head) (array-dimension content 0)))
          result))))

(defclass lockable-instance ()
  ((lock          :type t
                  :initform (bordeaux-threads:make-lock)
                  :reader lockable-instance/lock)
   (cond-variable :type t
                  :initform (bordeaux-threads:make-condition-variable)
                  :reader lockable-instance/cond-variable))
  (:documentation "Sequence that supports blocking on empty queues"))

(defmethod initialize-instance :after ((obj lockable-instance) &key lockable-instance-name)
  (setf (slot-value obj 'lock) (bordeaux-threads:make-lock lockable-instance-name))
  (setf (slot-value obj 'cond-variable) (bordeaux-threads:make-condition-variable :name lockable-instance-name)))

(defgeneric queue-pop-wait (queue)
  (:documentation "Attempts to pop one element off QUEUE. If the queue
is empty, wait until an element is added."))

(defclass blocking-queue (queue lockable-instance)
  ()
  (:documentation "A thread-safe version of QUEUE that allows waiting
for elements to be added to it."))

(defun make-blocking-queue (&key name)
  "Create a new instance of a blocking queue."
  (make-instance 'blocking-queue :lockable-instance-name name))

(defmethod seq-empty-p ((queue blocking-queue))
  (bordeaux-threads:with-recursive-lock-held ((lockable-instance/lock queue))
    (call-next-method)))

(defmethod queue-push ((queue blocking-queue) element)
  (bordeaux-threads:with-recursive-lock-held ((lockable-instance/lock queue))
    (let ((result (call-next-method)))
      (bordeaux-threads:condition-notify (lockable-instance/cond-variable queue))
      result)))

(defmethod queue-pop ((queue blocking-queue) &rest rest)
  (declare (ignore rest))
  (bordeaux-threads:with-recursive-lock-held ((lockable-instance/lock queue))
    (call-next-method)))

(defmethod queue-pop-wait ((queue blocking-queue))
  (bordeaux-threads:with-recursive-lock-held ((lockable-instance/lock queue))
    (loop
       while (seq-empty-p queue)
       do (bordeaux-threads:condition-wait (lockable-instance/cond-variable queue) (lockable-instance/lock queue)))
    (queue-pop queue)))

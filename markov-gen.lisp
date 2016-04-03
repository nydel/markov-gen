(ql:quickload '(:bordeaux-threads
		:cl-ppcre))

(defpackage :markov-gen
  (:nicknames :markov :mkgn :mg)
  (:use :cl :bordeaux-threads :cl-ppcre)
  (:export :*version*
	   :markov-gen-version
	   :version
	   :+eval-raw+
	   :+gen-text+
	   :+use-poe+))

#| :MARKOV-GEN version 1.0.101 Alpha. a packaged system for commonlisp.
    written by joshua ryan "nydel" trout on 2016-04-03 under LLGPL for fair use

    contact the author via email: nydel@36bit.com
    use subject: markov-gen.lisp


   this is a simple package that will take language input in the form of a string
   then separate the string into words determining their locations by positions of
   a #\Space or other whitespace, then analyze the string as to create a markov chain
   raw data association list, which can then be used to generate new language strings,
   using the natural weight (probability) occuring by selecting a random value in a
   list of words that occur in position n+1 in accordance with the position of the
   word in position n ... so if the word "person" occurs twice after the word "a" and
   the word "banana" occurs once after the word "a" then it is always 66% likely that
   the selection of a next word for current word "a" will result in "person" and 33%
   likely that it will result in "banana" because "person" has twice the weight of
   the word "banana" ... that is a simple example, and this package is equipped with
   a design capable of handling incredibly large strings and extremely complex markov
   data without compromising the purity of markov probability maths through something
   like the common practice of reducing probability samples to non-imaginary numbers
   usually representative of percentage and capped for accuracy at the nearest 0.01
   i.e. the nearest hundredth.

   to use this you'll need quicklisp to load :CL-PPCRE, i can't imagine that you don't
   already have ql installed but if you don't then find it for free at quicklisp dot
   org probably or maybe grab it off one of its many git repositories. all it does is
   allow me to write this package sloppily into one file instead of the old ways which
   were required to load dependencies packaged as asd/asdf etc.

   get yourself a bunch of text, such as a chapter of a book you like or all the song
   lyrics from some band's album. make sure the string is free of escape characters,
   especially #\. (period) and #\, (comma) and #\! (exclaimation point) ... it is most
   likely okay to leave in #\' (apostrophe) but why would you? once you have made the
   string, run

   (markov-gen:+eval-raw+ string)  ;; replacing "string" with either the string or a
   symbol pointing to it. this will be create the markov association list and it will
   be stored globally as markov-gen::*markov-raw-data*

   once you have processed the data, you can generate new text:

   (markov-gen:+gen-text+ first-word desired-length)

   example of that:

   (markov-gen:+gen-text+ "the" 250) ;; this will use your data to generate a string
   of 250 words, unless it runs into a word that has no possible next words; so, of
   course, it is best to use as lengthy of a string as possible for analysis, as this
   will reduce the chance of running into an early end, especially when trying to
   generate a very large amount of language, e.g. thousands of words.

   so after interpretation, to test, you could use this string: actually,
   i went ahead and stored what i wrote in markov-gen::*test-string*

   to test using it do (markov-gen:+eval-raw+ markov-gen::*test-string*)
               then do (markov-gen:+gen-text+ "this" 100)

|#

(in-package :markov-gen)

(defvar *version* nil)
(setf *version* "1.0.101a")

(defun version ()
  *version*)

(defun markov-gen-version ()
  (format t "~&:markov-gen commonlisp package version ~a~&" *version*))

(defvar *test-string* nil)
(setf *test-string* "this is some data that is pretty short and it would be good to use a lot of data instead of simply this little example, but the example will do fine as a quick initial test of the package please notice that there should have been a period after the word package but that i have taken it out because this works a lot better for now with no punctuation in the future i will add a feature that will parse periods as the end of a sentence meaning that the last word of a sentence will not have the first word of the next sentence associated as occuring after it but there are some subtle problems caused by doing that mostly on account of that this is a sloppy way to generate meaningful language so making it more complex will probably simply take away from the magic that might occur as if by accident when generating in this way")

;(defun test-process-text (str)
;  "redundant function, i left it in to remind myself of something for next version"
;  (let* ((list-of-words
;	  (split "\\s+" str))
;	 (list-without-duplicates
;	  (remove-duplicates list-of-words :test #'string-equal)))))

(defun search-word-and-return-word-after (word string-list)
  "find a word's next position in the string-list and return list (value-of-pos+1 pos)"
  (let* ((word-pos (position word string-list :test #'string-equal)))
    (if (null word-pos) nil
	(list (nth (1+ word-pos) string-list) word-pos))))

(defun collect-all-next-words (word string-list)
  "recursively find all words that occur after a given word"
  (let ((next-one (search-word-and-return-word-after word string-list)))
    (if (null next-one) nil
	(cons (car next-one)
	      (collect-all-next-words word (subseq string-list (1+ (cadr next-one))))))))

(defvar *markov-raw-data* nil) ;; use this to store the data you'll be using to generate

(defun eval-markov-raw-data (string)
  "from a string, create an assoc list with entries like (word (words that occur after word))"
  (let* ((string-list (split "\\s+" string))
	 (words (remove-duplicates string-list :test #'string-equal)))
    (loop for word in words collect (list word (collect-all-next-words word string-list)))))


(defun raw-data-from-string-list (str-list)
  (loop for word in str-list collect (list word (collect-all-next-words word str-list))))

;;; what follows is the exported evaluation function:


(defun +eval-raw+ (string)
  "eval a string for raw data and store it for use to generate"
  (setf *markov-raw-data*
	(eval-markov-raw-data string)))




;;; the above will analyze a string and create an assoc list of data
;;; the below will pull a word at random. so, above: analyze, below: generate.




(defun select-a-word-from-markov-data (word)
  "randomly select a next word using the weight of the markov chain data"
  (if (null *markov-raw-data*)
      (return-from select-a-word-from-markov-data
	(format *standard-output* "~&there is no data yet. use (markov-gen:+eval-raw+ string) first!~&"))
      (let* ((entry (assoc word *markov-raw-data* :test #'string-equal))
	     (after-words (cadr entry))
	     (number-of-words (length after-words)))
	(nth (random number-of-words) after-words))))

(defun generate-text (starting-word length-in-words)
  "generate the next-word for a word and the next-next and so-on"
  (if (<= length-in-words 0) nil
      (let ((next-word (select-a-word-from-markov-data starting-word)))
	(cons starting-word
	      (if (null next-word) nil
		  (generate-text next-word (1- length-in-words)))))))


;;; what follows is the exported generation function:

(defun +gen-text+ (first-word length-of-generation-in-words)
  "call this to generate text after the analysis phase"
  (generate-text first-word length-of-generation-in-words))


;;; some additional features:

(defun produce-small-poem ()
  (let* ((first-word (progn
		       (format t "what should be the first word? >> ")
		       (read-line)))
	 (pitch (+gen-text+ first-word (+ 5 (random 5)))))
    (let ((accepted-p (progn
			(format t "~&~a~&~%...is the first line. is this okay?" pitch)

					;(subseq pitch 1 (- (length pitch) 2)))
				;; this is meant to deal with that the results are a list of strings rather than one string ... will have to take something like ("hello" "there" "you" "sloppy" "lisp" "hacker") and turn it into "hello there you sloppy lisp hacker" via a function -- i hope -- it kind of feels like i might have to write that as a macro..
				
			(print "yes or no (y/n)")(read))))
      (if (string-equal accepted-p "y")
	  (progn
	    (format t "~&you accepted the line!~&")
	    (format t "~&add another line? yes or no (y/n)")
	    (let ((another-p (read)))
	      (if (string-equal another-p "y")
		  (produce-small-poem)
		  (format t "~&okay, finished with poem!~&"))))
	  (progn
	    (format t "~&you rejected the line.~&")
	    (format t "~&craft another potential line? yes or no (y/n)")
	    (let ((another-p (read)))
	      (if (string-equal another-p "y")
		  (produce-small-poem)
		  (format t "~&okay, finished with poem!~&"))))))))

;; at the moment, the produce-small-poem function doesn't actually push the accepted lines anywhere -- we're going to add that functionality as soon as we finish including the edgar allan poe string with a function that loads it up.


(defun symbol-list-to-string-list (list)
  (mapcar (lambda (y) (string-downcase (string y))) list))

(defun load-up-poe-string ()
  (with-open-file (poe #P"./sample-text.edgar-allan-poe.txt"
		       :direction :input)
    (loop for line = (read poe nil 'eof) until (equal line 'eof) collect line)))

(defun +use-poe+ ()
  (format *standard-output* "~&loading some edgar allan poe from a file then processing it into raw markov data; this may take a while, it takes about 10-15 seconds on my solid state drive with 24gb ra memory & a couple cpu clocking around 2.4ghz ... it's already happening, this message is to tell you that :MARKOV-GEN did not hang when you called (mg:+use-poe+) ... please wait...")
  (setf *markov-raw-data* (raw-data-from-string-list (symbol-list-to-string-list (load-up-poe-string))))
  (format *standard-output* "~&loaded sample-text.edgar-allan-poe.txt & made raw markov data.~&do (markov-gen:+gen-text+ \"the\" 100) to create a 100 word string beginning with the word 'the'~&~%or if you want to use it the way i do, generate poems line-by-line, using (+ 5 (random 5)) as the length-of-string-in-words variable, then keep the good lines and base the first word of the next line on something from the previous.~%"))

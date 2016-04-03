# markov-gen
use markov probability mathematics to generate strings of language

#| :MARKOV-GEN version 1.0.101 Alpha. a packaged system for commonlisp.
    written by joshua ryan "nydel" trout on 2016-04-03 under LLGPL for fair use

    contact the author via email: nydel@36bit.com
    use subject: markov-gen.lisp





   to test the system, load markov-gen.lisp then do:


   (mg:+use-poe+) ;; this will load up and create markov data from edgar allan poe
   

   (mg:+gen-text+ "the" (+ 5 (random 5))) ;; generate a 5-10 word line of poetry





   here is a sample piece of freeform this package wrote from poe's work:



   in her sleep, as angels all
   take, from out the chamber door,
   the fervour with which did she
   pine, forgotten now in her boundless
   floods and cushioned seats, by
   such bright green eyes driven, she
   prays to look not her dark thoughts
   in the eyes, in her fountain, as
   winged roses all flutter back to
   roam thy perfect fog, thy bliss,
   gracefully, she dies, to travel
   now only within a memory of some
   silent dell upon where, once, a
   shared slumber bound her dreams
   tightly to the mastery of another.






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

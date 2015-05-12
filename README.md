**Irritate the security services by embedding messages in spammy looking traffic**

Stegospam
=========

The idea is to use real looking spam from a corpus to steganographically transmit your secret 
message.

First of all you encrypt your message to its intended recipient. GPG is a reasonable way to do this.

Now you pipe the ciphertext to stegospam.pl. Stegospam first translates the ciphertext into a 
string made up of 0s and 1s. It breaks that string into random sized chunks. Then it looks up an
appropriate sentence for each chunk in its corpus database. You can read about how to initialize the
corpus database using import_corpus.pl in the inline docs for that program. Finally it prints out 
the spam it has generated -- your steganographic spam message. 

You can then use one or more email accounts that you control to transmit the spam to your recipient. 
Any listener (hallo GCHQ, NSA! ) will have a hard time distinguishing the stego-spam from real spam.
They will have to store spam indefinitely (or at least as long as they store PGPed email), which 
will, I hope, be annoying for them. The message itself is no less secure than would be a normally
encrypted message, but is a whole lot less obviously encrypted.

Possible Attacks and Caveat Emptor
------------------------------------------------

This program is really sort of a joke. Personally, I wouldn't trust any technology invented in the last 500 years to preserve my privacy, especially against Stasi-esque spooks like NSA and GCHQ. And I don't think you should either. However, I find it amusing to imagine said spooks finding themselves having to store spam email just in case it contains hidden messages. 

There are some obvious attacks and flaws that I can think of off the top of my head. 

* The corpus is know to the authorities in advance. This might be mitigated by  mean building your own corpus from spam you receive (or from the works of shakespeare or whatever). You do will find that import_corpus.pl is a rather slow if you do this, I consider this a flaw, but don't care enough to fix it.
* The distribution of sentence lengths may be vulnerable to a statistical attack. I've tried to mitigate this by using a gaussian random distribution of sentence lengths and giving a min and max sentence lengths as parameters. 
* The length of messages may also give an indication that the message is not genuine spam. I've not done  any work on this, but examining your corpus and splitting your message into seperate chunks (mailed at different times from different accounts) may be an option. 
* We strip out unusual characters and regularize spacing during corpus import into database, again leading to possible statistical analysis, similarly we insert paragraphs in a predictable manner.

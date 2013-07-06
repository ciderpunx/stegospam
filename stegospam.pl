#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.10.0;
use Data::Dumper;
use Readonly;
use DBI;
use DBD::SQLite;
use Readonly;

Readonly my $MIN_SENTENCE => 3; # minimum sentence length
Readonly my $MAX_SENTENCE => 8; # maximum sentence length
Readonly my $DEBUG        => 0; # switch on debugging output

## Probably don't want to change stuff from here onwards
Readonly my $USAGE => "$0 [-d|-e] < file.txt: use spam to transmit data from file.txt steganogrpahically";

die $USAGE unless $#ARGV == 0 && ($ARGV[0] eq '-d' || $ARGV[0] eq '-e');

my $mode = shift; 
my $dbh = DBI->connect("dbi:SQLite:dbname=corpus.sqlite3","","");

my $text = '';
$text .= $_ while (<>);

if ($mode eq '-d') {
	print bin2txt(spam2bin($text));
} 
else {
	say bin2spam(txt2bin($text));
}

# turn a string of 0s and 1s into a spam email
sub bin2spam {
	my $bin = shift;
	my $spam = '';
  my @chunk_offsets = get_chunk_offests(length $bin);
	my @chunks;
	my $i = 0;

	## split binary string into random length chunks
	for my $j (@chunk_offsets) {
		push @chunks, substr($bin, $i,$j);
		$i+=$j;
	}

	for my $chunk (@chunks) {
		my $sentence = find_sentence_from_parity_map($chunk);
		die "Unsupported parity map for sentence ($chunk). You probably need a bigger corpus." unless($sentence);
		$spam .= "$sentence ";
		if ((length $sentence) % 9 == 0) {$spam .= "\n\n"}
	}
	warn $spam if $DEBUG;
	warn join '',@chunks, ' bin2spam' if $DEBUG;
	return $spam
}

# turn a steganographic spam into a string of 0s and 1s
sub spam2bin {
	my $spam = shift;
	$spam =~ s/[\s\n]+/ /g;
	$spam =~ s/\.//g;
	my $s = join '', map {(length $_) % 2 == 0 ? 0 : 1} split /\W+/,$spam;
	warn "$s spam2bin" if $DEBUG;
	return $s;
}

# turn a string of 0s and 1s into whatever it was before
sub bin2txt {
	my $bin = shift;
	warn "$bin bin2txt" if $DEBUG;;
	pack "B*",$bin;
}

# turn string into a string made up of 0s and 1s
sub txt2bin {
	my $text = shift;
	my $q = join "", unpack "(B32)*", $text;
	warn "$q txt2bin" if $DEBUG;
	return $q;
}

# code borrowed from http://www.perlmonks.org/?node_id=29883
# returns a random integer on a standard distribution given a range and 
# a precision 
sub gauss_rands{
    my $t=0;
    $t = 0;
    $t+= ( rand()* ($_[0]/$_[1]) ) for(1..$_[1]);
    return int($t+1);
}

# returns an array of integers to use as chunk sizes to break a sentence into
# the chunks are random numbers on a standard distribution. 
sub get_chunk_offests {
	my $text_length = shift;
  my $words_accounted_for=0;
  my @chunk_offsets;
 	while ($words_accounted_for < $text_length) {
		my $x = $MIN_SENTENCE + gauss_rands(($MAX_SENTENCE-$MIN_SENTENCE),5); 
		if ($words_accounted_for + $x <= $text_length) {
			push @chunk_offsets, $x;
			$words_accounted_for += $x;
		}
		else {
			push @chunk_offsets, ($text_length - $words_accounted_for);
			$words_accounted_for += ($text_length - $words_accounted_for);
		}
	}
	return @chunk_offsets;
}

# Given a parity_map (i.e. mapping the length of the words in a section of text to 0 even, 1 odd)
# lookup a random spam sentence from the corpus db with the same parity map
sub find_sentence_from_parity_map {
	my $parity_map = shift; 
	my $sth = $dbh->prepare("SELECT sentence FROM sentences WHERE parity_map='$parity_map' ORDER BY RANDOM() LIMIT 1;");
	$sth->execute();
  my $row = $sth->fetch;
  return $row->[0];
}

__END__

=head1 NAME

stegospam: use spam to transmit data steganographically

=head2 VERSION

0.1

=head1 SYNOPSIS

$ gpg -o ciphertext -se plaintext
...
$ stegospam.pl -e < ciphertext > email_body
$ stegospal.pl -d < email_body | gpg -d

=head1 DESCRIPTION

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
==================================

This program is really sort of a joke. Personally, I wouldn't trust any technology invented in the last 
500 years to preserve my privacy, especially against Stasi-esque spooks like NSA and GCHQ. And I 
don't think you should either. However, I find it amusing to imagine said spooks finding themselves 
having to store spam email just in case it contains hidden messages. 

There are some obvious attacks and flaws that I can think of off the top of my head. 

* The corpus is know to the authorities in advance. This might be mitigated by  mean building your 
own corpus from spam you receive (or from the works of shakespeare or whatever). You do will find that 
import_corpus.pl is a rather slow if you do this, I consider this a flaw, but don't care enough to fix it.
* The distribution of sentence lengths may be vulnerable to a statistical attack. I've tried to mitigate
this by using a gaussian random distribution of sentence lengths and giving a min and max sentence lengths
as parameters. 
* The length of messages may also give an indication that the message is not genuine spam. I've not done 
any work on this, but examining your corpus and splitting your message into seperate chunks (mailed at 
different times from different accounts) may be an option. 
* We strip out unusual characters and regularize spacing during corpus import into database, again leading 
to possible statistical analysis, similarly we insert paragraphs in a predictable manner.


=head1 REQUIREMENTS

sqlite3
DBI
DBD::SQLite
Perl 5.10.0 (not tested on earlier versions)
Data::Dumper

=head1 COPYRIGHT AND LICENCE

           Copyright (C)2013 Charlie Harvey

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 
 2 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be 
 useful, but WITHOUT ANY WARRANTY; without even the implied 
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR 
 PURPOSE.  See the GNU General Public License for more 
 details.

 You should have received a copy of the GNU General Public 
 License along with this program; if not, write to the Free
 Software Foundation, Inc., 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.
 Also available on line: http://www.gnu.org/copyleft/gpl.html

=cut


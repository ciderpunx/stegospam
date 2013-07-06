#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.10.0;
use Data::Dumper;
use Readonly;
use DBI;
use DBD::SQLite;

unless (-f 'corpus.sqlite3') {
	open my $db, ">", 'corpus.sqlite3';
	close $db;
}
my $dbh = DBI->connect("dbi:SQLite:dbname=corpus.sqlite3","","");
my $ct = $dbh->prepare("CREATE TABLE IF NOT EXISTS sentences (id INTEGER PRIMARY KEY, sentence TEXT, length INTEGER, parity_map TEXT);")
;
$ct->execute;
my $ci = $dbh->prepare("CREATE INDEX IF NOT EXISTS idx_parity_map ON sentences (parity_map);");
$ci->execute;

my $corpus = '';
$corpus .= $_ while (<>);

my @sentences = split /\s*[\.\?\!]\s*/, $corpus;
my $i = 0;

say "Importing corpus, may take a while";
$dbh->do("PRAGMA synchronous=OFF");
for my $sentence (@sentences) {
	# we do a bit of cleaning up here
	$sentence =~ s/[\r\n]+/ /g;
	$sentence =~ s/\.//g;
	$sentence =~ s/[^\w\s\?\$\!\,\-\:\\\/]//g;
	$sentence =~ s/ (\W) /$1/g;
	$sentence =~ s/\s+/ /g;
	$sentence =~ s/^\W+//;
	next unless $sentence && length $sentence > 5;
	$sentence = ucfirst $sentence . '.';
	my $length = length $sentence;

	# read rtl. split on non spaces, assign zero for even length words 1 for odd length by 
	# mapping over the list of words, then join the 0s and 1s together. Simple.
	my $parity_map = join '',map {(length $_) % 2 == 0 ? 0 : 1} split /\W+/, $sentence;
	say "Importing sentence: " . $i++;
	my $sth = $dbh->prepare("INSERT INTO sentences (sentence, length, parity_map) VALUES (?, ?, ?)");
	$sth->execute($sentence, $length, $parity_map);
}
say "Done";

__END__

=head1 NAME

import_corpus.pl : imports a corpus of text (spam perchance?) to use for encoding steganographic messages that look like common or garden spam.

=head2 VERSION

0.1

=head1 SYNOPSIS

$ wget http://www.aueb.gr/users/ion/data/enron-spam/preprocessed/enron1.tar.gz
$ tar xvzf enron1.tar.gz
$ cat enron1/spam/* | grep -v '^Subject:' > corpus
$ import_corpus.pl < corpus

Corpus is now in corpus.sqlite3 


=head1 REQUIREMENTS

sqlite
Perl 5.10.0 (not tested on earlier versions)
Data::Dumper
Readonly
DBI
DBD::SQLite3


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

=head1 SEE ALSO

____________________________

=cut


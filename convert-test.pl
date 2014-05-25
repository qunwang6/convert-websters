#!/usr/bin/perl -w
# 
# 5/22/14 ADP

use strict;

# read
my @entries = do('read.pl');

# emit
for my $entry (@entries) {
  for my $key (qw(headword pronunciation part_of_speech etymology 
    specialty definition)) 
  {
    my $value = $entry->{$key};
    print "$key: $value\n" if defined($value);
  }
  print "\n";
}
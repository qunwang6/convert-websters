#!/usr/bin/perl -w
#
# needs input with local line endings, first 27 lines stripped, and last 362
# lines stripped
#
# like: tr -d "\r" < 29765.txt.utf-8 | tail -n +27 | head -n 973878
# 
# 5/21/14 ADP

use strict;
use open qw(:std :utf8);

# paragraph mode
local $/ = "";

# read paragraphs from stdin
my @paragraphs = <>;

warn "Read " . scalar(@paragraphs) . " paragraphs\n";

# find indices of word paragraphs
my @word_paragraph_indices;
for (my $i = 0 ; $i < scalar(@paragraphs) ; $i++) {
  # split to lines
  my @lines = split("\n", $paragraphs[$i]);

  # if this is a word paragraph, save the index
  if ($lines[0] =~ /^[A-Z0-1 \-\'\;]+$/) {
    push(@word_paragraph_indices, $i);
  }
}

warn "Found " . scalar(@word_paragraph_indices) . " words\n";

# collect entries
my @entries;
for (my $ii = 0 ; $ii < scalar(@word_paragraph_indices) ; $ii++) {
  # entry paragraph range
  my $i = $word_paragraph_indices[$ii];
  my $next = $word_paragraph_indices[$ii+1] || scalar(@paragraphs);

  # entry paragraphs
  my @entry_paragraphs = @paragraphs[$i .. $next-1];

  # word paragraph lines
  my @lines = split("\n", $entry_paragraphs[0]);
  my $word = $lines[0];
  push @entries, {
    word => $word,
    paragraphs => \@entry_paragraphs
  };
}

warn "Collected " . scalar(@entries) . " entries\n";

# semantic parsing
for my $entry (@entries) {
  # entry paragraphs
  my @paragraphs = @{$entry->{paragraphs}};

  # first paragraph
  my $first_paragraph = shift @paragraphs;
  my @first_paragraph_lines = split("\n", $first_paragraph);

  # headword
  $entry->{headword} = shift @first_paragraph_lines;

  # sub-head (pronunciation, part of speech, etymology)
  my $subhead = join(" ", @first_paragraph_lines);

  # specialty (perhaps there's a better term for this) may be at the end
  # of the sub-head in parens
  $subhead =~ s/\s+(\([\w\. ]+\))\s*$//;
  $entry->{specialty} = $1;

  # etymology may follow Etym:
  if ($subhead =~ /\ Etym:\ /) {
    ($subhead, $entry->{etymology}) = split(' Etym: ', $subhead);
  }

  # if the remaining subhead exceeds 60 characters in length and no specialty
  # or etymology was found, it is probably a definition for a word lacking 
  # a full subhead
  if (defined($entry->{specialty}) || defined($entry->{etymology}) ||
    length($subhead) < 60) 
  {
    # pronunciation is first, optionally followed by a comma and part of speech
    ($entry->{pronunciation}, $entry->{part_of_speech}) = split(', ', $subhead);
  } else {
    # remove the parts that won't have been in this kind of subhead
    delete $entry->{specialty};
    delete $entry->{etymology};
    delete $entry->{part_of_speech};

    # get the whole subhead again (just in case)
    $subhead = join(" ", @first_paragraph_lines);

    # take the first part of the entry to be the subhead
    $entry->{definition} = $subhead;
  }

  # definition
  my $definition = join("\n", map {tr/\n/ /s; $_} @paragraphs);
  if (defined($entry->{definition})) {
    $entry->{definition} .= $definition;
  } else {
    $entry->{definition} = $definition;
  }

  # strip 'Defn: ' from the beginning of definition paragraphs
  $entry->{definition} =~ s/^Defn:\s+//gm;

  # remove paragraphs
  delete $entry->{paragraphs};
}

warn "Parsed " . scalar(@entries) . " entries\n";

return @entries;
#!/usr/bin/perl -w 

#
#    Copyright 2012 Adhemar Zerlotini Neto 
#    Author: Adhemar Zerlotini Neto (azneto@gmail.com)
#
#    mergeShuffledFastqSeqs.pl is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 3 of the License, or
#    (at your option) any later version.
#
#    mergeShuffledFastqSeqs.pl is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
 

use strict;
use Getopt::Long;

my $usage = "

$0 -f1 <file 1> -f2 <file 2> -r <regular expression> -o <output file name> -t
$0 -h

-f1 <file 1>                    : Fastq input file containing sequences identified as 1
-f2 <file 2>                    : Fastq input file containing sequences identified as 2
-r <regular expression>         : Regular expression to locate the ID without the 1 and 2 in each sequence's description line
                                  Eg. '^@(\\S+)/[1|2]\$' to indicate the ID is after the @ symbol and before a / symbol (\@HWI-EAS269:2:1:4:590#0/1)
                                  Eg. '^@(\\S+)\\s[1|2]\\S+\$' to indicate the ID is after the @ symbol and before a space symbol (\@HWI-ST829:138:D071VACXX:1:1101:1131:2048 1:N:0:ATCACG)
-o <output file name>           : Prefix name for the result files
                                  Eg. 'mergedSequences'
-t                              : Save two files rather than a interleaved one
-h                              : Help message

";


$| = 1;

my $file1;
my $file2;
my $regex;
my $outname;
my $two;
my $help;

GetOptions ("f1=s" => \$file1,
            "f2=s" => \$file2,
            "r=s" => \$regex,
            "o=s" => \$outname,
            "t!"  => \$two,
            "h!"  => \$help);

if ($help) {
        die $usage;
}

die "\nAll parameters are required",$usage unless( $file1 && $file2 && $regex && $outname);

open (FILEA, "< $file1") or die "\nCouldn't open file1 ($file1).",$usage;
open (FILEB, "< $file2") or die "\nCouldn't open file2 ($file2).",$usage;

if(defined $two) {
 
  open (FASTQ1OUT, "> $outname.1.fastq") or die "\nCouldn't open fastq 1 outfile ($outname.1.fastq)",$usage;
  open (FASTQ2OUT, "> $outname.2.fastq") or die "\nCouldn't open fastq 2 outfile ($outname.2.fastq)",$usage;
  open (NOMATCH1OUT, "> $outname.nomatch1.fastq") or die "\nCouldn't open no match1 outfile ($outname.nomatch1.fastq)",$usage;
  open (NOMATCH2OUT, "> $outname.nomatch2.fastq") or die "\nCouldn't open no match2 outfile ($outname.nomatch2.fastq)",$usage;
 
} else {
 
  open (FASTQOUT, "> $outname.merged.fastq") or die "\nCouldn't open fastq outfile ($outname.merged.fastq)",$usage;
  open (NOMATCH1OUT, "> $outname.nomatch1.fastq") or die "\nCouldn't open no match1 outfile ($outname.nomatch1.fastq)",$usage;
  open (NOMATCH2OUT, "> $outname.nomatch2.fastq") or die "\nCouldn't open no match2 outfile ($outname.nomatch2.fastq)",$usage; 
}


my %idsFileA;

print "\nLoading the first file...";

while(my $line = <FILEA>) {

  chomp $line;

  if($line =~ /$regex/) {
     
     my $nodiscard =  <FILEA>;
     my $discard = <FILEA>;
     $nodiscard .=  "+\n";
     $nodiscard .=  <FILEA>;
     $idsFileA{$1} =  $nodiscard;

  } else {

     die "The regular expression provided doesn't match sequence description.",$usage;

  }

}

print "\nMatching the entries...";

while(my $line = <FILEB>) {

    chomp $line;

    my $id;
    my $idsFileB;

    if($line =~ /$regex/) {

       $id = $1;

       $idsFileB .=  <FILEB>;
       my $discard = <FILEB>;
       $idsFileB .=  "+\n";
       $idsFileB .=  <FILEB>;

    } else {

       die "The regular expression provided doesn't match sequence description.",$usage;

    }

    if($idsFileA{$id}) {

        if(defined $two) {

            print FASTQ1OUT "@" . $id . "-1\n";
            print FASTQ1OUT $idsFileA{$id};

            print FASTQ2OUT "@" . $id . "-2\n";
            print FASTQ2OUT $idsFileB;


        } else {

            print FASTQOUT "@" . $id . "-1\n";
            print FASTQOUT $idsFileA{$id};

            print FASTQOUT "@" . $id . "-2\n";
            print FASTQOUT $idsFileB;

        }

        $idsFileA{$id} = '';
        delete $idsFileA{$id};

    } else {

        print NOMATCH2OUT "@" . $id . "-2\n";
        print NOMATCH2OUT $idsFileB;

    }

}

print "\nSaving the remaining sequences...";

for my $id (keys %idsFileA) {

        print NOMATCH1OUT "@" . $id . "-1\n";
        print NOMATCH1OUT $idsFileA{$id};

        $idsFileA{$id} = '';
        delete $idsFileA{$id};
}

if(defined $two) {

   close(FASTQ1OUT);
   close(FASTQ2OUT);

} else {

   close(FASTQOUT);

}

close(NOMATCH1OUT);
close(NOMATCH2OUT);

print "\nDONE\n\n";



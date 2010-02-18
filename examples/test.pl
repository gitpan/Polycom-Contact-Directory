#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Polycom::Contact::Directory; 

my $dir = Polycom::Contact::Directory->new('000000000000-directory.xml'); 

print "Contacts in directory:\n";
for my $contact ($dir->all)
{
	print "\t$contact\n";
}

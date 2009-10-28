#!perl -w

#============================================================================ 
#Name        : scanbuildlog.pl 
#Part of     : Helium 

#Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
#All rights reserved.
#This component and the accompanying materials are made available
#under the terms of the License "Eclipse Public License v1.0"
#which accompanies this distribution, and is available
#at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
#Initial Contributors:
#Nokia Corporation - initial contribution.
#
#Contributors:
#
#Description: 
#============================================================================

# ==============================================================================
#  %name:          scanbuildlog.pl %
#  Part of:        juno_build
#
#  %version:	   1 %
#  %date_modified: Mon Feb 06 17:21:13 2006 %
#
#  See POD text at the end of this file for usage details.
# ==============================================================================

use strict;
use Getopt::Long;
use Pod::Usage;
use XML::Simple;
use lib "$ENV{'BUILD_DRIVE'}\\epoc32\\tools";
use Scanlog;
use XML::Parser::Expat;

my $help        = 0;
my $man         = 0;
my $unique      = 0;
my $logfilename = '';

GetOptions('unique' => \$unique,
           'log=s'  => \$logfilename,
           'man'    => \$man,
           'help|?' => \$help)
  or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;
$logfilename = shift unless $logfilename;
my $logfile;

if ($logfilename)
{
    open(LOGFILE, $logfilename) or die("Can't open '$logfilename': $!\n");
    $logfile = \*LOGFILE;
}
else
{
    $logfile = \*STDIN;
}

#<!DOCTYPE logfile SYSTEM "logfile.dtd">
#<?xml-stylesheet type="text/xsl" href="logfile.xsl"?>
print <<EOT;
<?xml version="1.0" encoding="ascii"?>
EOT
print("<logfile name=\"$logfilename\">\n");

my %logentry  = ();
my $phase     = '';
my $component = '';
my $parser = new XML::Parser::Expat;

while (<$logfile>)
{
    chomp;
    next if Scanlog::CheckForIgnore($_);

    ($phase = $1) =~ s/\\/\\\\/ and next
      if /^=== (.+) started ... ... .. (..):(..):(..)/;
    $phase = $1 and next if /^=== (.+) started ... ... .. (..):(..):(..)/;
    $component = $1 and next if $phase && /^=== $phase == (\S+)/;
    if ($phase && /^=== $phase finished ... ... .. (..):(..):(..)/)
    {
        $component = '';
        next;
    }

    my $logrec = {line    => $.,
                  content => $parser->xml_escape($_)};

    $logrec->{severity} = 'info'
      if Scanlog::CheckForMigrationNotes($_)
      or Scanlog::CheckForRemarks($_);

      if ( Scanlog::CheckForErrors($_)
      or Scanlog::CheckForNotBuilt($_)
      or Scanlog::CheckForMissing($_) )
    {
        $logrec->{severity} = 'error';
    }
    $logrec->{severity} = 'warn' if Scanlog::CheckForWarnings($_);
    next unless $logrec->{severity};

    print XMLout($logrec, rootname => 'logentry', noescape => 0);
}

print("</logfile>\n");

__END__

=head1 NAME

scanbuildlog - Scan EBS build log for errors and warnings

=head1 SYNOPSIS

perl scanbuildlog.pl [-h] | -l <log file>

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-l>

Specify the log file to parse.

=back

=head1 DESCRIPTION

Prints out a summary of the errors, warnings and informational
messages found in the log file in an XML format conforming to the
following DTD:

 <!ELEMENT logfile (logentry*)>
 <!ELEMENT logentry (#PCDATA)>
 <!ATTLIST logentry
   severity (error|warn|info) #REQUIRED
   line     CDATA             #REQUIRED
   errfile  CDATA             #IMPLIED
   errline  CDATA             #IMPLIED>

=head1 SEE ALSO

=cut

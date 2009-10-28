#!perl -w

#============================================================================ 
#Name        : xml2make.pl 
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
#  %name:          xml2mak.pl %
#  Part of:        Juno Build Tools
#
#  %derived_by:    wbernard %
#  %version:	   6.1.2 %
#  %date_modified: Fri Jul  7 14:42:30 2006 %
#
#
#  V2
#    - Custom version that use ISIS framework.
#
#  See POD text at the end of this file for usage details.
# ==============================================================================

BEGIN
{
	push @INC, "/isis_sw/build_tools/packages";
}

use strict;
use IO::Handle;
use ISIS::XMLManip;
use File::Basename;
use Getopt::Long;
use Pod::Usage;

my $MAKNAME = 'Makefile';
my $INPUT   = '';
my $MAXDEPS = 0;
my $PHONY   = 0;
my $MULTI   = 0;
my $SERIALIZE = 1;
my $help    = 0;
my $man     = 0;
my $verbose = 0;

GetOptions('name=s'     => \$MAKNAME,
           'i|input=s'    => \$INPUT,
           'maxdeps=i'  => \$MAXDEPS,
           'multi!'     => \$MULTI,
           'phony!'     => \$PHONY,
           'serialize!' => \$SERIALIZE,
           'verbose'    => \$verbose,
           'man'        => \$man,
           'help|?'     => \$help)
  or pod2usage(2);
pod2usage(1) if ($help);
pod2usage(-exitstatus => 0, -verbose => 2) if $man;


# Parallelizable build commands are grouped in "stages" by genxml,
# while commands that must be run in series are placed in their own
# single command stage.  We combine stages containing only a single
# command into a "sequence" by specifying consecutive command rules to
# be dependent.  Both sequences and stages may be put into submake
# files if the multi option is specified.

my $currstage = undef;
my %stage     = ();
my @sequence  = ();

print "Creating '$MAKNAME'...\n" if ($verbose);
open(MAINMAKE, ">$MAKNAME")
  or die("Can't open makefile \"$MAKNAME\" for write: $!\n");

print(MAINMAKE "SHELL=cmd.exe\n\n");
print(MAINMAKE "ALL: ALL_END\n\n");

#<ISIS - oligrant - Replace simple text opening with xml parsing>
my $xmlInput;
if ($INPUT)
{
	$xmlInput = XMLManip::ParseXMLFile($INPUT);
}
else
{
	my $stdin = new IO::Handle;
	$stdin->fdopen(fileno(STDIN), "r") or die("Couldn't open STDIN: $!\n");
	$xmlInput = XMLManip::ParseXMLFileHandle($stdin);
	$stdin->close();
}
my $cmdNode  = $xmlInput->Child('Commands', 0);
#or die("Can't parse $INPUT TBS file\n");
#</ISIS>

my @steps = ();
my @allstage = ();
foreach my $execNode (@{$cmdNode->Child('Execute')})
{
    if($execNode->Attribute('ID') and
       $execNode->Attribute('Stage') and
       $execNode->Attribute('Cwd') and
       $execNode->Attribute('CommandLine')
      )
    {
    		unless ($currstage)
    		{
    			$currstage = $execNode->Attribute('Stage');
    		}
                
        if ($execNode->Attribute('Stage') ne $currstage)
        {
        	
        	# generate stages
        	if ( $MULTI )
        	{        		
    			&GenerateSubMake($currstage, \@steps, $MULTI );
			print (MAINMAKE &GenerateStageRule("stage$currstage", (($currstage-1>0)?"stage".($currstage-1):''), $currstage, "${MAKNAME}_${currstage}"));
       			#print (MAINMAKE &GenerateRule( "stage$currstage", (($currstage-1>0)?"stage".($currstage-1):''), undef, "-\$(MAKE) -k -f ${MAKNAME}_${currstage}"));
        	}
        	else
        	{
        		print (MAINMAKE &GenerateStage( $currstage, \@steps , $MULTI)."\n");
        	}
        	
        	push @allstage, "stage".$currstage;
        	# Adding current to the list
        	@steps = ();
        	$currstage = $execNode->Attribute('Stage');
        	push @steps, $execNode;
        }
        else
        {
        	# Adding new step to the list
        	#print "Adding\n";
        	push @steps, $execNode;
        }
    }
}

if (scalar(@steps))
{
	if ( $MULTI )
	{        		
		&GenerateSubMake($currstage, \@steps, $MULTI );
		print (MAINMAKE &GenerateStageRule("stage$currstage", (($currstage-1>0)?"stage".($currstage-1):''), $currstage, "${MAKNAME}_${currstage}"));
#		print (MAINMAKE &GenerateRule( "stage$currstage", (($currstage-1>0)?"stage".($currstage-1):''), undef, "\$(MAKE) -k -f ${MAKNAME}_${currstage}"));
	}
	else
	{
		print (MAINMAKE &GenerateStage( $currstage, \@steps , $MULTI)."\n");
	}
 	push @allstage, "stage".$currstage;
}

if ( $MULTI )
{
	print (MAINMAKE "ALL_END: stage$currstage\n") if ( $currstage );		
}
else
{
	print (MAINMAKE "ALL_END: ".join (' ',@allstage)."\n");
}

close (MAINMAKE);



sub GenerateSubMake
{
	my ($currstage, $steps) = @_;
	print "Creating '${MAKNAME}_${currstage}'...\n" if ($verbose);
	open (SUBMAKE, ">${MAKNAME}_${currstage}");
	print(SUBMAKE "ALL: ALL_END\n\n");
	print (SUBMAKE &GenerateStage( $currstage, $steps , 1)."\n");
	print (SUBMAKE "ALL_END: ");
	foreach (@$steps) { print (SUBMAKE "id".$_->Attribute('ID')." "); }
	print (SUBMAKE "\n");
	close (SUBMAKE);
}

sub GenerateStage
{
	my ($stage, $steps, $multi) = @_;
		
	my $txt = '';
	unless ($multi)
	{
		$txt  .= "stage$stage: ";
		$txt .= "stage".($stage-1)." " if ($stage-1>0);
		
		foreach my $s ( @$steps ) {	$txt .= "id".$s->Attribute('ID')." ";	}
		$txt.= "\n";
	}
	
	foreach my $s ( @$steps )
	{
		$txt .= &GenerateRule("id".$s->Attribute('ID'), '', $s->Attribute('Cwd'), $s->Attribute('CommandLine'), $s->Attribute('Component'), $stage, $s->Attribute('ID'));
	}	
	return $txt;
}

sub GenerateStageRule
{
	my ($left, $right, $stage, $makefile) = (shift, shift, shift, shift);
	my $txt = "$left : $right\n";
	$txt .= "\t\@echo ===-------------------------------------------------\n";
	$txt .= "\t\@echo === Stage=$stage\n";
	$txt .= "\t\@echo ===-------------------------------------------------\n";
	$txt .= "\t\@timestamp \"=== Stage=$stage started at \"\n";
	$txt .= "\t\$(MAKE) -k -f $makefile\n";
	$txt .= "\t\@timestamp \"=== Stage=20 finished \"\n\n";
	return $txt;
}

sub GenerateRule
{
	my ($left, $right, $dir, $cmd, $component, $stage, $id) = (shift,shift || '', shift, shift, shift, shift, shift);
	my $commandline = $cmd;
	$commandline =~ s/\|/^|/g;
	my $txt = "$left: $right\n";
	$txt .= "\t\@echo === Stage=$stage == $component\n";
	$txt .= "\t\@echo -- $commandline\n";
	$txt .= "\t\@echo --- ElectricCloud Executed ID $id\n";
	$txt .= "\t\@timestamp \"++ Started at \"\n";
	$txt .= "\t\@timestamp_hires \"+++ HiRes Start \"\n";
	$txt .= "\t\@echo Chdir $dir \n";
	$txt .= "\t\@-cd $dir && $cmd\n";
	$txt .= "\t\@timestamp_hires \"+++ HiRes End \"\n";
	$txt .= "\t\@timestamp \"++ Finished at \"\n\n";
	return $txt;
}

__END__

=head1 NAME

xml2mak - Create a makefile from an EBS XML file

=head1 SYNOPSIS

perl xml2mak.pl [-h] [-man]  [-multi]  [-name=<makefile name>] [-i=<XML file>]

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-name=F<makefile name>>

Specify the root makefile name.  Defaults to F<Makefile>.  If
B<-multi> is specified, the additional makefiles will be named
<root>_<#>.<root extension>.

=item B<-[no]phony>

If phony is specified, targets are defined as C<.PHONY> in the
makefile.  Default is not to declare phony targets.

=item B<-[no]serialize>

B<-noserialize> removes dependencies between adjacent rules in a
sequence, even though these dependencies may be specified in the XML
file.  Sequenced rules are then free to be executed concurrently.
Default is to serialize sequences as defined in the XML file.

=item B<-maxdeps=<number>>

Specify the maximum number of dependencies for a given target.  This
will split the target into multiple rules if necessary.

=item B<-multi>

Split the makefile into multiple files, separating them by stages and
sequences.

=back

=head1 DESCRIPTION

Extracts the component list and commands from an EBS XML and generates
a makefile using the same command staging order.  Default make target
is "ALL".

=head1 SEE ALSO

L<xml2cmp|scripts::xml2cmp>

=cut

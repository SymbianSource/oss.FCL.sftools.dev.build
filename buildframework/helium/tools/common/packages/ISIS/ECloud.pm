#
# Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description: 
#
#--------------------------------------------------------------------------------------------------
# Name   : ECloud.pm
# Path   : D:\Work\isis_sw\build_tools\packages\ISIS\
# Use    : Manage ECloud instances.
#
# Synergy :
# Perl %name: ECloud.pm % (%full_filespec: ECloud.pm-1.1.6:perl:fa1s60p1#2 %)
# %derived_by: wbernard %
# %date_created: Fri Jul  7 15:15:54 2006 %
#
# Version History :
# v1.0.1 (30/03/2006)
#  - Updated ecloud patching.
#
# v1.0.0 (16/02/2006) :
#  - First version of the module.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   ECloud package.
#
#--------------------------------------------------------------------------------------------------

package ECloud;

use strict;
use warnings;
use ISIS::XMLManip;
use ISIS::Logger3;
use ISIS::Registry;
use Cwd;

use constant ISIS_VERSION     => '1.0.0';
use constant ISIS_LAST_UPDATE => '16/02/2006';
use constant ISIS_EC_CONFIG   => '\\isis_sw\\build_tools\\ec_configs.xml';

my @__batchs;
my @__generators;
my @__abld;

BEGIN
{
	@__batchs = map { $ENV{EPOCROOT}.'epoc32\\tools\\'.$_ } ('alp2csh.bat', 'bldmake.bat', 'CHARCONV.BAT', 'CNVTOOL.BAT', 'cshlpcmp.bat', 'efreeze.bat', 'epocrc.bat', 'eshell.bat', 'evalid.bat', 'fixupsym.bat', 'genbuild.bat', 'hpsym.bat', 'instcol.bat', 'makmake.bat', 'maksym.bat', 'memtrace.bat', 'metabld.bat', 'SNMTOOL.BAT', 'splitlog.bat');
	@__generators = ($ENV{EPOCROOT}.'epoc32\\tools\\bldmake.pl', $ENV{EPOCROOT}.'src\\cedar\\generic\\tools\\e32toolp\\bldmake\\bldmake.pl');
	@__abld = ($ENV{EPOCROOT}.'epoc32\\tools\\abld.pl', $ENV{EPOCROOT}.'src\\cedar\\generic\\tools\\e32toolp\\bldmake\\abld.pl');
}

## @function GetAgentByNodeList
# This function return a hash of node available on the cluster.
# Each hash is node contains the number of agent on the cluster.
#
sub GetAgentByNodeList
{	
	my %list;
	my $regfile  = new Registry(ISIS_EC_CONFIG, { error_level => 0 });
	my $registry = $regfile->{'ec_configs'}->{'basic'};
	my $cmd = "cmtool --cm=".$registry->{'cluster_manager'}." getagents";

	my @res = `$cmd`;
	shift(@res);

	foreach my $line (@res)
	{		
		my @r = split(',', $line);
		$list{$r[2]}->{$r[1]}->{'BuildId'} = $r[7];
	}
	return \%list;
}

##
#
#
sub ClusterExecute
{
	my ($node, $command) = (shift,shift);
	my $regfile  = new Registry(ISIS_EC_CONFIG, { error_level => 1 });
	my $registry = $regfile->{'ec_configs'}->{'basic'};
	my $cm = $registry->{'cluster_manager'};
	
	system ( "C:\\ECloud\\i686_win32\\bin\\clusterexec.exe --cm=$cm --nodes=$node --use-shell \"$command\"" );
}

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
	my ($class, $configtype, $custom) = (shift, shift || 'basic', shift || {});
	
	my $regfile  = new Registry(ISIS_EC_CONFIG, { error_level => 1 });
	my $registry = $regfile->{'ec_configs'}->{$configtype};
	
	my $var = bless {
		__volatile_opts   => __ec_volatile_types->new(),
		__emulation_table => __ec_emulation_table->new(),
		__root_dir        => $ENV{EPOCROOT},
	}, $class;

	foreach my $key (keys %$registry)
	{ $var->{'__'.$key} = $registry->{$key}; }

	foreach my $key (keys %$custom)
	{ $var->{'__'.$key} = $custom->{$key}; }

	return $var;
}

#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{
	my ($self, $method) = (shift, our $AUTOLOAD);
	return if $method =~ /::DESTROY$/;
	
	my $key = $method;
	$key =~ s/^.*\:\://g;
	$key =~ s/([A-Z])/ $1/g;
	$key = '__'.join('_', map { lc($_) } split(' ', $key));

	unless(exists $self->{$key})
	{
		warn "Method $method is invalid!\n";
		return;
	}

	$self->{$key} = shift if @_;
	return $self->{$key};
}

#--------------------------------------------------------------------------------------------------
sub Emulation
{
	my ($self, $make) = (shift, shift);
	return $self->{__emulation_table}->Emulation($make, @_);
}

#--------------------------------------------------------------------------------------------------
sub AddVolatileType
{
	my ($self) = (shift);
	foreach my $type (@_)
	{ $self->{__volatile_opts}->VolatileType($type, 1); }
}

#--------------------------------------------------------------------------------------------------
sub RemoveVolatileType
{
	my ($self) = (shift);
	foreach my $type (@_)
	{ $self->{__volatile_opts}->VolatileType($type, 0); }
}

#--------------------------------------------------------------------------------------------------
# Parameters:        %1 = log directory                              
#                    %2 = history filename prefix                    
#                    %3 = xml/makefile name                          
#                    %4 = directory (incl. trailing \) of xml file   
#                    %5 = build label                                
#                    %6 = Top level target (defaults to all)     

# %EC_BIN_DIR%\emake --emake-priority=%EC_PRIORITY%
#                    --emake-maxnodes=%EC_MAXNODES%
#                    --emake-job-limit=%EC_JOBLIMIT%
#                    --emake-mem-limit=%EC_MAXMEM%
#                    --emake-volatile=%EC_VOLATILE_OPTS%
#                    --emake-history=merge
#                    --emake-emulation-table make=symbian,emake=symbian,nmake=nmake
#                    --emake-class=%EC_BUILDCLASS%
#                    --emake-build-label=%EC_BUILDLABEL%
#                    --emake-cm=%EC_CM%
#                    --emake-root=%EPOCROOT%
#                    --emake-debug=%EC_DEBUG_OPTS%
#                    --emake-logfile=%EC_LOG_DIR%%1\%1.%EC_TARGET%.emake.%EC_DEBUG_OPTS%.dlog
#                    --emake-annodetail=%EC_ANNO_OPTS%
#                    --emake-annofile=%EC_LOG_DIR%%1\%1.%EC_TARGET%.emake.anno.xml
#                    --emake-historyfile=%EC_HISTORY_DIR%%2.%EC_TARGET%.emake.data %EC_NOREG%
#                    -f %EC_MAKEFILE_DIR%%EC_TARGET% %EC_PRINTDIRECTORY% %EC_TOPLEVELTGT% 2>&1 | \ec\tools\tee %EC_LOG_DIR%%1\%1.%EC_TARGET%.emake.stdout    
#--------------------------------------------------------------------------------------------------
sub Command
{
	my ($self, $xml) = (shift, shift || '\%TARGET\%');
	$xml =~ s/\.xml$//;
	
	return join('', $self->{__bin_dir}, "emake ",
	                " --emake-priority=", $self->{__priority},
	                " --emake-maxnodes=", $self->{__max_nodes},
	                " --emake-job-limit=", $self->{__job_limit},
	                " --emake-mem-limit=", $self->{__mem_limit},
	                " --emake-volatile=", $self->{__volatile_opts}->Print(),
	                " --emake-history=", $self->{__history_opts},
	                " --emake-emulation-table ", $self->{__emulation_table}->Print(),
	                " --emake-class=", $self->{__build_class},
	                " --emake-build-label=", $self->{__build_label},
	                " --emake-cm=", $self->{__cluster_manager},
	                " --emake-root=", $self->{__root_dir},
	                " --emake-debug=", $self->{__debug_opts},
	                " --emake-logfile=", $self->{__log_dir}, $xml, ".emake.", $self->{__debug_opts}, ".dlog",
	                " --emake-annodetail=", $self->{__anno_opts},
	                " --emake-annofile=", $self->{__log_dir}, $xml, ".emake.anno.xml",
	                " --emake-historyfile=", $self->{__history_dir}, lc($self->{__build_class}), '_', $xml, '_history.emake.data',
	                " -f ", $self->{__makefile_dir}, $xml, " ", $self->{__print_dir}, " ", $self->{__top_level_tgt}, " 2>&1",
	                " | ", $self->{__tools_dir},"tee ", $self->{__log_dir}, lc($self->{__build_class}), '_', $xml, '.emake.stdout');
}

#--------------------------------------------------------------------------------------------------
sub Execute
{
	my ($self, $xmlInput, $patch) = (shift, shift, shift);
	$patch = 1 unless (defined($patch));
	
	$self->__patch_symbian_code() if ($patch);
	
	# Execute emake
	my $cmd = $self->Command($xmlInput);
	print "----------------------------------------------------------------------------\n";
	print "$cmd";
	print scalar(`$cmd`), "\n";
	print "----------------------------------------------------------------------------\n";
	
	# Collect agent performance metrics for the run
	system('tclsh '.$self->{__tools_dir}.'agentcmd --cm='.$self->{__cluster_manager}."\"session performance\" > ".$self->{__log_dir}.$xmlInput.'.agentraw');
	system('tclsh '.$self->{__tools_dir}.'agentsummary '.$self->{__log_dir}.$xmlInput.'.agentraw > '.$self->{__log_dir}.$xmlInput.'.agentstats');
	system('copy '.$self->{__history_dir}.lc($self->{__build_class}).'_'.$xmlInput.'_history.emake.data '.$self->{__log_dir});
	
	$self->__unpatch_symbian_code()  if ($patch);
}

sub ExecuteXML
{
	my ($self, $xmlInput) = (shift, shift);
	my ($path, $file) = ($xmlInput =~ /^(.*?)([^\\\/]+)\.xml$/);
	
	$ENV{PATH} = $self->{__bin_dir}.';'.$ENV{PATH};
	$self->{__build_label} = uc($file) if($self->{__build_label} eq 'NOLABEL');
	
	$self->__generate_makefiles($path, $file);
	
	$self->__patch_symbian_code();
	
	# Execute emake
	my $cmd = $self->Command($file);
	print "----------------------------------------------------------------------------\n";
	print scalar(`$cmd`), "\n";
	print "----------------------------------------------------------------------------\n";
	
	# Collect agent performance metrics for the run
	system('tclsh '.$self->{__tools_dir}.'agentcmd --cm='.$self->{__cluster_manager}."\"session performance\" > ".$self->{__log_dir}.$file.'.agentraw');
	system('tclsh '.$self->{__tools_dir}.'agentsummary '.$self->{__log_dir}.$file.'.agentraw > '.$self->{__log_dir}.$file.'.agentstats');
	system('copy '.$self->{__history_dir}.lc($self->{__build_class}).'_'.$file.'_history.emake.data '.$self->{__log_dir});
	
	$self->__unpatch_symbian_code();
}

#--------------------------------------------------------------------------------------------------
sub __generate_makefiles
{
	my ($self, $path, $file) = (shift, shift, shift);
	
	system('md '.$self->{__makefile_dir}) unless(-e $self->{__makefile_dir});

	my $cmd  = $self->{__perl_dir}.'perl.exe ';
	$cmd    .= '\\isis_sw\\build_tools\\packages\\ISIS\\xml2mak.pl -multi -noserialize ';
	$cmd    .= '-name='.$self->{__makefile_dir}.$file.' -input='.$path.$file.'.xml';

	print "----------------------------------------------------------------------------\n";
	print scalar `$cmd`, "\n";
}

#--------------------------------------------------------------------------------------------------
sub __patch_symbian_code
{
	my ($self) = (shift);
	
	print "---------------------------------------\n";
	print "current working directory :\n";
	print cwd(), "\n";
	print "---------------------------------------\n";

	# backup makefiles.
	print("backing-up makefiles\n");
	system('md '.$self->{__ec_dir}.'assets') unless(-e $self->{__ec_dir}.'assets');
	system('xcopy /Y /I '.$self->{__makefile_dir}.' '.$self->{__ec_dir}.'assets');
	
	# backup symbian gnu make.
	print("backing-up symbian gnu make\n");
	system('copy /Y '.$ENV{EPOCROOT}.'epoc32\\tools\\make.exe '.$ENV{EPOCROOT}.'epoc32\\tools\\make.symbian.exe');
	
	# patch .bat files which call perl using %PATH% to call perl explicitly.
	print("patching batch files\n");
	foreach my $bat (@__batchs)
	{
		print "Patching file \'$bat\': ";
		system('attrib -r $bat');
		system('move /Y '.$bat.'.make_orig '.$bat) if(-e $bat.'.make_orig');
		system('copy /Y '.$bat.' '.$bat.'.make_orig');
		system($self->{__perl_dir}."perl.exe -Wpe \"s/perl /C:\\\\\\\\APPS\\\\\\\\actperl_5.6.1_635\\\\\\\\bin\\\\\\\\perl.exe /\" < ".$bat.'.make_orig > '.$bat);
	}

	# patch abld
	print("patching abld files\n");
	foreach my $abld (@__abld)
	{
		system("attrib -r $abld");
		system("move /y $abld.make_orig $abld") if ( -e "$abld.make_orig");
		system("copy $abld $abld.make_orig");
		system($self->{__perl_dir}."perl.exe -Wpe \"next if (/WHAT/); s/make -r/emake -i -r/\" < $abld.make_orig > $abld");		
	}
	
	# patch scripts that generate .bat files which call perl using %PATH% to call perl explicitly.
	print("patching scripts that generate batch files\n");
	foreach my $gen (@__generators)
	{
		print "Patching file \'$gen\': ";
		system('attrib -r $gen');
		system('move /Y '.$gen.'.make_orig '.$gen) if(-e $gen.'.make_orig');
		system('copy /Y '.$gen.' '.$gen.'.make_orig');
		system($self->{__perl_dir}."perl.exe -Wpe \"s/perl -S /C:\\\\\\\\APPS\\\\\\\\actperl_5.6.1_635\\\\\\\\bin\\\\\\\\perl.exe -S /\" < ".$gen.'.make_orig > '.$gen);
	}
}

#--------------------------------------------------------------------------------------------------
sub __unpatch_symbian_code
{
	my ($self) = (shift);
	
	system('del '.$self->{__root_dir}.'epoc32\\tools\\make.symbian.exe');
	
	# restore default batch files.
	print ("unpatching batch files\n");
	foreach my $bat (@__batchs)
	{
		print "Restoring file \'$bat\': ";
		system('move /Y '.$bat.'.make_orig '.$bat) if(-e $bat.'.make_orig');
	}

	# unpatch abld's.
	print("patching abld files\n");
	foreach my $abld (@__abld)
	{
		print "Restoring file \'$abld\': ";
		system('move /Y '.$abld.'.make_orig '.$abld) if(-e $abld.'.make_orig');
	}
	
	# unpatch bldmake.pl s.
	print ("unpatching generators\n");
	foreach my $gen (@__generators)
	{
		print "Restoring file \'$gen\': ";
		system('move /Y '.$gen.'.make_orig '.$gen) if(-e $gen.'.make_orig');
	}
}

1;

#--------------------------------------------------------------------------------------------------
#
#   ECloud Emulation Table.
#
#--------------------------------------------------------------------------------------------------
package __ec_emulation_table;

sub new
{
	bless { make  => 'symbian',
		      emake => 'symbian',
		      nmake => 'nmake',
		    }, shift;
}

sub Emulation
{
	my ($self, $make) = (shift, shift);
	return unless exists $self->{$make};
	
	$self->{$make} = shift if @_;
	return $self->{$make};
}

sub Print
{
	my $self = shift;
	return join(',', map { $_.'='.$self->{$_} } keys %{$self});
}

1;

#--------------------------------------------------------------------------------------------------
#
#   ECloud Volatile Types.
#
#--------------------------------------------------------------------------------------------------
package __ec_volatile_types;

sub new
{
	bless { def   => 1,
		      info  => 1,
		      class => 1,
		      mmp   => 1,
		    }, shift;
}

sub VolatileType
{
	my ($self, $type, $add_or_remove) = (shift, shift, shift);
	$type =~ s/^\.//g;
	
	if($add_or_remove)
	{ $self->{$type} = 1; }
	else
	{ delete $self->{$type}; }
}

sub Print
{
	my $self = shift;
	return join(',', map { '.'.$_ } keys %{$self});
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

	ISIS::ECloud - Electric Cloud module.

=head1 SYNOPSIS

	use ISIS::ECloud;
	
	# Create a new ecloud instance with max nodes to 100.
	my $ec = new ECloud({ max_nodes => 100 });
	
	$ec->MemLimit(100000);
	
	$ec->Execute('full_build.xml');

=head1 DESCRIPTION

=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------

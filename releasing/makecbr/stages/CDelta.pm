# Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package CDelta;

use strict;
use Carp;

use FindBin;
use lib $FindBin::Bin."\\..";
use Cwd;
use File::Spec;
use IO::Handle;
use Time::Local;
use Parallel::ForkManager;
use base qw(CProcessStage);

# use constants for config directive names
use constant CONFIG_BASELINE_NAME           => 'GT+Techview baseline component name';
use constant CONFIG_BASELINE_VERSION        => 'Last baseline version';
use constant CONFIG_GT_COMPONENTS_LIST      => 'GT component list';
use constant CONFIG_TV_COMPONENTS_LIST      => 'Techview component list';
use constant CONFIG_RELEASE_VERSION         => 'Release version';
use constant CONFIG_INTERNAL_VERSION        => 'Internal version';
use constant CONFIG_MRP_UPDATED_COMPONENTS  => 'Updated components';
use constant CONFIG_PREINSTALLED_COMPONENTS => 'Preinstalled components';
use constant CONFIG_MAX_PARALLEL_TASKS      => 'Max Parallel Tasks';

my $keeptemp;

$| = 1;                       # autoflush output

sub AUTOLOAD {

    my $self = shift;
    my $method = (split '::', $CDelta::AUTOLOAD)[-1];

    return if $method eq 'iOptions'; # prevent recursion...
    my $config = $self->iOptions(); # ...on this call

    # delegate to our CConfig if possible (e.g. Get, Set, Print, Error, etc.)
    return $config->$method(@_) if UNIVERSAL::can($config, $method);

    carp "$CDelta::AUTOLOAD not implemented";
    return undef;
}

sub DESTROY {} # required - prevents AUTOLOAD destroying the CConfig

sub CheckOpts {

    my $self = shift;

    my @required = (
        CONFIG_BASELINE_NAME,
        CONFIG_BASELINE_VERSION,
        CONFIG_GT_COMPONENTS_LIST,
        CONFIG_TV_COMPONENTS_LIST,
        CONFIG_RELEASE_VERSION,
        CONFIG_INTERNAL_VERSION);

    $self->CheckOpt($_) for @required;

    my @files = map $self->Get($_), (CONFIG_GT_COMPONENTS_LIST, CONFIG_TV_COMPONENTS_LIST);

    $self->Die("Required file missing: $_") for grep !-e, @files;
}

sub Run {

    my $self = shift;

    # get list of components in this release
    my $release = $self->ListReleaseComponents();

    $self->Print("\t$_ $release->{$_}")
        for sort { lc($a) cmp lc($b) } keys %$release;

    # get previous release component info
    my $previous = $self->ListPreviousComponents(
        $self->Get(CONFIG_BASELINE_NAME),
        $self->Get(CONFIG_BASELINE_VERSION)) or return;

    $self->Print("\t$_ $previous->{$_}")
        for sort { lc($a) cmp lc($b) } keys %$previous;

    # get preinstalled component info
    my $preinstalled = $self->ListPreinstalledComponents();

    $self->Print("\t$_ $preinstalled->{$_}")
        for sort { lc($a) cmp lc($b) } keys %$preinstalled;

    # Need to check that required preinstalled components are present
    my @noSource = grep $release->{$_} eq '*nosource*', keys %$release;
  
    if (my @missingComponents = grep !exists $preinstalled->{$_}, @noSource) {
        foreach my $component (@missingComponents) {
           $self->Error("Required pre-installed component $component does not exist in the environment");     
        }
        return 0;
    }  

    # Need to check that there are not preinstalled components which have not been specified in
    # techviewcomponents.txt or gt_components.txt
    if (my @extraComponents = grep !exists $release->{$_}, keys %$preinstalled) {
        foreach my $extraComponent (@extraComponents) {
            $self->Error("Pre-installed component $extraComponent is not specified in " . $self->Get(CONFIG_GT_COMPONENTS_LIST) . " or  " . $self->Get(CONFIG_TV_COMPONENTS_LIST)); 
        }
        return 0;
    }

    # add information to the environment database about MRP's that will be included in the environment
    foreach my $component (keys %$release) {
        next if ($release->{$component} eq '*nosource*');
        next if (exists $preinstalled->{$component});
        
        my $cmd = "envdata $component -m " . $release->{$component};
        $self->_runcmd($cmd); 
    }

    # store preinstalled list for use by CCheckEnv
    $self->Set(CONFIG_PREINSTALLED_COMPONENTS, [ %$preinstalled ]);

    # get updated components (i.e. MRP file changed)
    my $updated = $self->Get(CONFIG_MRP_UPDATED_COMPONENTS);

    # determine components to validate starting with the previous release
    my $validate = { %$previous };

    # ignore removed components
    delete $validate->{$_} for grep !exists $release->{$_}, keys %$validate;

    # ignore preinstalled components
    delete $validate->{$_} for keys %$preinstalled;
    
    # ignore updated components
    delete $validate->{$_} for @$updated;

    # do validation - get list of dirty components
    my $dirty = $self->ListDirtyComponents($validate);

    # list added components
    my @added = grep !exists $previous->{$_}, keys %$release;

    # list all components for publishing
    my $prepare = [grep !exists $preinstalled->{$_}, (@$dirty, @added, @$updated, $self->Get(CONFIG_BASELINE_NAME))];

    # do prep and return result as stage completion status
    return $self->PrepComponents($prepare, $release);
}

sub ListReleaseComponents {

    my $self = shift;
    my $components = {};
    my @files = map $self->Get($_), (CONFIG_GT_COMPONENTS_LIST, CONFIG_TV_COMPONENTS_LIST);

    $self->Print("Determining this release content");

    for my $file (@files) {

        if (!open(LIST, $file)) {
            $self->Error("Couldn't open file: $file ($!)");
            return;
        }

        while (<LIST>) {

            next if /^\s*#/; # skip comments

            # line format: component_name mrp_file
            if (/^\s*(\S+)\s+(\S+)\s*$/) {
                $components->{lc($1)} = $2;
            } else {
                $self->Warning("Badly formed data in $file at line $. ($_)");
            }
        }

        close(LIST);
    }

    return $components;
}

sub ListPreviousComponents {

    my $self = shift;
    my $baseline = shift;
    my $version = shift;

    return {} if $version =~ /^__initial/i; # special - no previous release

    $self->Print("Determining previous release content ($baseline $version)");

    # load or locate a module from a CBR tools installation *ugh*
    if (!eval { require IniData }) {

        my $found = 0;

        # search PATH for the module and add the location to @INC if found
        for my $dir (split ';', $ENV{PATH}) {
            next unless -e File::Spec->catfile($dir, 'IniData.pm');
            push @INC, $dir;
            $found++;
        }

        if (!$found) {
            $self->Error("Couldn't find a CBR tools installation");
            return;
        }
    }

    # load required modules and create objects
    require IniData;
    require RelData;

    my $ini = eval { IniData->New() };

    if (!defined $ini or length $@) {
        $self->Error("Error occurred while attempting to read reltools.ini ($@)");
        return;
    }

    my $component = eval { RelData->Open($ini, $baseline, $version) };

    if (!defined $component or length $@) {
        $self->Error("Couldn't open component $baseline version $version ($@)");
        return;
    }

    my $environment = $component->Environment();

    return { map { (lc($_), $environment->{$_}) } keys %$environment };
}

sub ListPreinstalledComponents {

    my $self = shift;
    my $components = {};

    $self->Print("Determining preinstalled components");

    $self->Component("CDelta: envinfo"); # For Scanlog compatibility

    $self->_runcmd('envinfo -n', sub {

        # skip 3 line header (blank line, Component       Version, blank line)
        return if $. < 4;

        # check output conforms to expected format
        if (!/^\s*(\S+)\s+(\S+)\s*$/) {
            $self->Error("EnvInfo output format is different to that expected");
        }

        # break line on whitespace
        my($component, $version) = split(/\s+/, $_);

        # add component and version to list of preinstalled components
        $components->{lc($component)} = $version;

    });

    return $components;
}

sub ListDirtyComponents {
   #
   # This method has been modified in response to REQ9701. It now calls the external 'validaterel'
   # process in a separate, forked process (one for each component being validated) and all these
   # processes run in parallel (if the Max Parallel Tasks runtime option is greater than zero). It
   # is possible to optimize parallelization for the machine on which MakeCBR is running by means
   # of Max Parallel Tasks.
   #

   my $self = shift;
   my $components = shift;
   my $child = "";
   my $output = "";
   my %child_output;
   my $indecision = 0;
   my $dirty_list = {};
   my ($start_time, $elapsed) = 0;
   my ($pid, $comp, $status, $started);
   my $max_tasks = $self->iOptions()->Get(CONFIG_MAX_PARALLEL_TASKS);
   my $parallel = new Parallel::ForkManager($max_tasks); 

   $| = 1;                       # autoflush output

   $self->iOptions()->Print("\nMaximum number of parallel processes is ${max_tasks}\n");

   #
   # Define callback routine to run when each child process starts up
   #

   $parallel->run_on_start (
      sub {
         ($pid, $comp) = @_;

#        if ($comp ne "1") {
#            print("-- validation started for ${comp}\n");                      # (DEBUG)
#        }

         #
         # Perl 5.6.1 on a laptop sometimes hangs if too many processes are
         # forked at once, but a brief nap seems to cure this behaviour (it
         # may not be necessary in production)
         #

         if ($comp ne "1") {
#             print "before to wait 0.2 secs\n";
             select(undef, undef, undef, 2); # sleep for 1/5th of a second
             #select(undef, undef, undef, 4); # sleep for 1/5th of a second
         }

#         print "-- leaving run_on_start for ${comp}\n";
      }
   );

   #
   # Define callback routine to capture exit codes from child processes
   #

   $parallel->run_on_finish (
      sub {
         ($pid, $status, $comp) = @_;
         my $verdict;

         if ($comp ne "1") {
            if ($status == 1) {
               $verdict = "clean";
            }
            elsif ($status == 0) {
               $verdict = "dirty";
               $dirty_list->{$comp}++;
            }
            else {
               $verdict = "undecided";
               $indecision = 1;
            }

#           print("-- validation finished for ${comp} (${verdict})\n");        # (DEBUG)
         }
      }
   );

   #
   # Define callback routine to run when maximum processes reached
   #

   $parallel->run_on_wait (
      sub {
         print("-- maximum (${max_tasks}) parallel processes reached\n");      # (DEBUG)
      }
#     }, 0.5   # optional repeat interval
   );

   #
   # Store the time (in seconds) immediately before going parallel
   #

   $start_time = &get_seconds();

   $self->iOptions()->Print("\nValidating all installed components\n");

   print("\nSeparate output from each validation task follows:-\n");
   print("================================================================\n");

   #
   # Loop through the list of components passed into this method
   #

   for my $component (sort { lc($a) cmp lc($b) } keys %$components) {
      #
      # Spawn a parallel (child) process
      #

      $parallel->start($component) and next;

      ##########################################
      # This is the start of the child process #
      ##########################################

      my $line = "";
      my $message = "";
      my $clean = 1;
      my $decision = 0;
      my $child_pid = $$;
      my $version = $components->{$component};
      my ($text, $childname, $childtalk);
      my $child_start;
      my $child_finish;
      my $child_lifetime;

      $| = 1;                       # autoflush output

      $child_pid =~ s/-//;

      #
      # Store the time (in seconds) when the child was born
      #

#     $child_start = &get_seconds();                                        # (DEBUG)

      #
      # Construct the validaterel command
      #

      my $command = qq(validaterel -sf $component "$version");

      $message = "Validating ${component} against version ${version}\n";
      $message .= "Executing ${command}\n";

      #
      # Execute the validaterel command re-directing STDERR
      # stream to STDOUT; scan each output line for "dirty"
      # or "clean" status; capture all validaterel's output
      #

      $command .= " 2>&1";

      if (open (COMMAND, "$command|")) {
         foreach my $line (<COMMAND>) {
            if (($line =~/Status dirty/) ||
                ($line =~/Status binaries clean, source dirty/)) {
               $clean = 0;
            }

            if (($line =~/Status clean/) ||
                ($line =~/Status dirty/) ||
                ($line =~/Status pending release/) ||
                ($line =~/Status binaries clean, source dirty/)) {
               $decision = 1;
            }

            $message .= $line;
         }

         close(COMMAND);
      }
      else {
         die "Could not execute command \"${command}\". ${!}\n";
      }

      #
      # Print the output in distinct, ordered blocks (goes into a separate
      # file on the server if ordinary Perl 'print' is used instead of the
      # Component object method but calling that method in children causes
      # "attempt to access an unreferenced scalar" errors)
      #

      $self->iOptions()->Print("${message}");
      $self->iOptions()->Print("================================================================\n");

      #
      # Calculate the child's total lifetime
      #

#     $child_finish = &get_seconds();                                    # (DEBUG)
#     $child_lifetime = $child_finish - $child_start;                    # (DEBUG)
#     print("[times: start ${child_start}, finish ${child_finish}, total ${child_lifetime}]\n"); # (DEBUG)

      #
      # Return special value if decision has not been made
      #

      if (!$decision) {
         $clean = -1;
      }
     
      ########################################
      # This is the end of the child process #
      ########################################

      $parallel->finish($clean);
   }

   #
   # The parent process must wait for all its children to finish
   #

   $parallel->wait_all_children;

   if ($indecision) {
      $self->iOptions()->Error("One or more components could not be validated");
   }

   #
   # Calculate the total time it took to run all parallel processes
   #

   $elapsed = &get_seconds() - $start_time;

   $self->iOptions()->Print("Validation of installed components complete (" . &convert_seconds($elapsed) . ")\n");

   return [ keys %$dirty_list ];
}

sub PrepComponents {

    my $self = shift;
    my $components = shift;
    my $release = shift;
    my $version = $self->Get(CONFIG_RELEASE_VERSION);
    my $internal = $self->Get(CONFIG_INTERNAL_VERSION);
    my $last = '';

    for my $component (sort { lc($a) cmp lc($b) } @$components) {

        next if $component eq $last; # prevent reprocessing (in case of duplicates)

        $self->Component($component);
        $self->Print("Preparing component $component");

        if (!exists $release->{$component}) { # should never happen
            $self->Error("Component $component is not supposed to be in this release");
            return 0;
        }

        my $command = qq(preprel -v $component $version $internal -m $release->{$component});
      
        $self->Component($component); # For Scanlog compatibility

        if ($self->_runcmd($command)) {
            $self->Error("Preprel failed for component: $component");
            return 0;
        }

        $last = $component;
    }

    return 1;
}

sub _runcmd {

    my $self = shift;
    my $cmd = shift;
    my $lineproc = shift || sub {};

    $self->Print("Executing $cmd");

    if (!open(OUTPUT, "$cmd 2>&1 |")) {
        $self->Error("Couldn't execute: $cmd ($!)");
        return -1;
    }

    while (<OUTPUT>) {
        chomp;
        $self->Print($_);
        $lineproc->($_); # call callback with line data
    }

    close(OUTPUT);

    my $exit = $? >> 8;

    if ($exit) {
        $self->Error("Command completed with nonzero exit code: $exit");
    } else {
        $self->Print("Command completed successfully");
    }

    return $exit;
}

sub get_seconds {
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());

   my $epoch_secs = timelocal($sec, $min, $hour, $mday, $mon, $year);

   return $epoch_secs;
}

sub convert_seconds {
   my $time_secs = shift;
   my $time_str;
   my $seconds;
   my $minutes;
   my $hours;

   $seconds   =  $time_secs % 60;
   $time_secs = ($time_secs - $seconds) / 60;
   $minutes   =  $time_secs % 60;
   $time_secs = ($time_secs - $minutes) / 60;
   $hours     =  $time_secs % 24;

   $time_str = sprintf("%02d:%02d:%02d", $hours, $minutes, $seconds);

   return $time_str;
}

1;

=pod

=head1 NAME

CDelta - determines environment differences and prepares for release.

=head1 SYNOPSIS

This class runs as a stage of makeCBR. No alternate usage is supported.

An instance is created using the inherited constructor and processing is
invoked using the overloaded Run() method.

=head1 DESCRIPTION

The CDelta stage replaces the CValidate and CPrepEnv stages and provides
the functionality required to determine which components need to be re-
published to make the new baseline. This process now takes account of the
fact that there may be preinstalled components (e.g. ISCs) which should
not be republished (ever).

=head1 METHODS

=head2 New($config)

Inherited constructor - see L<CProcessStage>.

=head2 AUTOLOAD($method)

Attempts to delegate unknown method calls to the CConfig object provided to
the constructor at instantiation. The CConfig object does configuration
handling and logging and this AUTOLOAD arrangement allows the CConfig methods
to be called directly on $self, rather than having to assign to a variable
or use the not-so-pretty $self->iOptions()->Foo() notation.

=head2 CheckOpts()

Checks required configuration directives are present and sensible prior to
using them.

=head2 Run()

Main control method - contains the business logic for the stage.

=head2 ListReleaseComponents()

Reads the GT and Techview component list files to get the full list of
components to be published in this release. Returns a hashref where the
keys are the component names and the values are their MRP file paths.

=head2 ListPreviousComponents($baseline, $version)

Returns a hashref of component name => version for a given baseline
component name and version. This is determined by interrogating the reldata
file of the specified component (making use of CBR tools libraries which
are dynamically loaded).

=head2 ListPreinstalledComponents()

Returns a hashref of component name => version currently installed in the
environment. This is determined by running envinfo.

=head2 ListDirtyComponents(\%components)

Returns an arrayref of component names for those components differing to
their version in the previous release (as provided in %components). This is
determined by running validaterel on each component.

=head2 PrepComponents(\@components, \%release)

Prepares the given list of component names for later publishing. This is
achieved by calling preprel for each component specified, using the MRP file
location provided in %release (the return value of ListReleaseComponents()).

=head1 SEE ALSO

L<CProcessStage> (base class) and L<CConfig> (configuration and logging).

=head1 COPYRIGHT

Copyright (c) 2005-2007 Symbian Software Ltd. All rights reserved.

=cut

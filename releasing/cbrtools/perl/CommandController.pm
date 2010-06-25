# Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#

package CommandController;

use strict;


#
# Constants.
#

use constant READER_SEMAPHORE_NAME => "CommandControllerReaderSemaphore_";
use constant WRITER_SEMAPHORE_NAME => "CommandControllerWriterSemaphore_";
use constant MAX_NUM_CONCURRENT_READERS => 100;
use constant CMD_INDEPENDANT => 0; # Commands that can be run regardless of what else is running.
use constant CMD_ENV_READER => 1;  # Commands that only read the environment.
use constant CMD_ENV_WRITER => 2;  # Commands that modify the environment.

my %commandInfo = (
 		   EnvMembership => CMD_INDEPENDANT,
		   CleanRemote => CMD_INDEPENDANT,
		   ExportEnv => CMD_INDEPENDANT,
		   ExportRel => CMD_INDEPENDANT,
		   CopyRel => CMD_INDEPENDANT,
		   ImportEnv => CMD_INDEPENDANT,
		   ImportRel => CMD_INDEPENDANT,		
		   LatestVer => CMD_INDEPENDANT,
		   PullEnv => CMD_INDEPENDANT,
		   PushEnv => CMD_INDEPENDANT,
		   PushRel => CMD_INDEPENDANT,
		   PullRel => CMD_INDEPENDANT,
		   DeltaEnv => CMD_INDEPENDANT,
		   BinInfo => CMD_ENV_READER,
		   SourceInfo => CMD_ENV_READER,
		   DiffEnv => CMD_ENV_READER,
		   DiffRel => CMD_ENV_READER,
		   ModNotes => CMD_ENV_READER,
		   ViewNotes => CMD_ENV_READER,
		   BuildRel => CMD_ENV_READER,
		   EnvSize => CMD_ENV_READER,
		   MakeSnapShot => CMD_ENV_READER,
		   CleanEnv => CMD_ENV_WRITER,
		   EnvInfo => CMD_ENV_WRITER,
		   GetEnv => CMD_ENV_WRITER,
		   GetRel => CMD_ENV_WRITER,
		   GetSource => CMD_ENV_WRITER,
		   InstallSnapShot => CMD_ENV_WRITER,
		   MakeEnv => CMD_ENV_WRITER,
		   MakeRel => CMD_ENV_WRITER,
		   RemoveRel => CMD_ENV_WRITER,
		   RemoveSource => CMD_ENV_READER,
		   PrepEnv => CMD_ENV_WRITER,
		   PrepRel => CMD_ENV_WRITER,
		   ValidateEnv => CMD_ENV_WRITER,
		   ValidateRel => CMD_ENV_WRITER,
		   EnvData => CMD_ENV_WRITER
		  );


#
# Public.
#

sub New {
  my $pkg = shift;
  my $self = {};
  bless $self, $pkg;
  $self->{iniData} = shift;
  $self->{command} = shift;
  unless ($self->{iniData}->Win32ExtensionsDisabled()) {
    $self->OpenSemaphores();
    unless ($self->CanRun()) {
      die "Error: Cannot run $self->{command} because another command is already running\n";
    }
  }
  return $self;
}


#
# Private.
#

sub CanRun {
  my $self = shift;
  $self->{canRun} = 0;
  my $commandType = $self->CommandType();
  if ($commandType == CMD_INDEPENDANT) {
    $self->{canRun} = 1;
  }
  elsif ($commandType == CMD_ENV_READER) {
    unless ($self->WriterRunning()) {
      $self->{canRun} = 1;
      $self->IncReadersRunning();
    }
  }
  elsif ($commandType == CMD_ENV_WRITER) {
    if (($self->NumReadersRunning() == 0) and not $self->WriterRunning()) {
      $self->{canRun} = 1;
      $self->SetWriterRunning();
    }
  }
  return $self->{canRun};
}

sub DESTROY {
  my $self = shift;
  if ($self->{canRun}) {
    my $commandType = $self->CommandType();
    if ($commandType == CMD_INDEPENDANT) {
      # Nothing to do.
    }
    elsif ($commandType == CMD_ENV_READER) {
      $self->DecReadersRunning();
    }
    elsif ($commandType == CMD_ENV_WRITER) {
      $self->ClearWriterRunning();
    }
  }
}

sub OpenSemaphores {
  my $self = shift;
  my $currentEnvironment = Utils::CurrentDriveLetter() . lc(Utils::EpocRoot());
  $currentEnvironment =~ s/[:\\\/]+/_/g; # Can't have slashes in semaphore name
  
  require Win32::Semaphore;
  # No longer 'use', as that fails with some versions of Perl
  $self->{writerSemaphore} = Win32::Semaphore->new(0, 2, WRITER_SEMAPHORE_NAME . $currentEnvironment) or die; # 2 because when counting the semaphore, it need to be incremented and then decremented (release(0, $var) doesn't work).
  $self->{readerSemaphore} = Win32::Semaphore->new(0, MAX_NUM_CONCURRENT_READERS, READER_SEMAPHORE_NAME . $currentEnvironment) or die;
}

sub CommandType {
  my $self = shift;
  die unless exists $commandInfo{$self->{command}};
  return $commandInfo{$self->{command}};
}

sub WriterRunning {
  my $self = shift;
  my $writerRunning = SemaphoreCount($self->{writerSemaphore});
  die if $writerRunning > 1;
  return $writerRunning;
}

sub SetWriterRunning {
  my $self = shift;
  SemaphoreInc($self->{writerSemaphore});
}

sub ClearWriterRunning {
  my $self = shift;
  SemaphoreDec($self->{writerSemaphore});
}

sub NumReadersRunning {
  my $self = shift;
  return SemaphoreCount($self->{readerSemaphore});
}

sub IncReadersRunning {
  my $self = shift;
  SemaphoreInc($self->{readerSemaphore});
}

sub DecReadersRunning {
  my $self = shift;
  SemaphoreInc($self->{readerSemaphore});
}

sub SemaphoreCount {
  my $semaphore = shift;
  my $count;
  $semaphore->release(1, $count) or die;
  $semaphore->wait();
  return $count;
}

sub SemaphoreInc {
  my $semaphore = shift;
  $semaphore->release(1) or die;
}

sub SemaphoreDec {
  my $semaphore = shift;
  $semaphore->wait();
}

1;

=head1 NAME

CommandController.pm - Provides a means of controlling which commands can run concurrently within a single environment.

=head1 DESCRIPTION

Certain commands can reliably be run while others are running, whereas others must be run in isolation. This class has responsibility for defining a set of rules regarding concurrent running of commands and ensuring that they are followed. Each command is classified into one of three types:

=over 4

=item 1 Independant

Commands of this type can be run regardless of whatever else may also be running at the time because they neither read nor modify the environment. Commands of this type:

 		   EnvMembership
		   CleanRemote
		   ExportEnv
		   ExportRel
		   ImportEnv
		   ImportRel		
		   LatestVer
		   PullEnv
		   PullRel
		   PushEnv
		   PushRel
		   DeltaEnv


=item 2 Environment readers

Commands of this type can be run provided there aren't any writers running. Commands of this type:

		   BinInfo
		   DiffEnv
		   DiffRel
                   MakeSnapShot
		   ModNotes
                   RemoveSource
		   ViewNotes

=item 3 Environment writers

Commands of this type may modify the state of the environment, and so may only run providing there are no other writers or readers running. Commands of this type:

		   CleanEnv
		   EnvInfo
		   GetEnv
		   GetRel
		   GetSource
                   InstallSnapShot
		   MakeEnv
		   MakeRel
		   RemoveRel
		   PrepEnv
		   PrepRel
		   ValidateEnv
		   ValidateRel

=back

To enforce these runs, multiple instances of C<CommandController> (running in different processes) need to know what else is running at any particular point in time. This information could have been stored in a file, but this has the significant problem that commands that are prematurely killed by the user (perhaps by hitting ctrl-c), they will not cleanup after themselves and so the environment could get stuck in an invalid state. To avoid this problem, a pair of Win32 semaphores are used to count the number of readers and writers currently active at any point in time. Note, only the counting properties of the semaphores are used, which is somewhat unusual (normally semaphores are used to control the execution of threads). The advantage of this scheme is that even if a command is prematurely killed by the user, its handles to the semaphoreswill be released. This may mean that for a period of time the semaphores may have invalid value, but once all commands that are currently running have completed, the semaphores will be destroyed (kernel side) and the environment is guaranteed of being in a 'ready to run' state.

=head1 INTERFACE

=head2 New

Expects to be passed an C<IniData> reference and the name of the command that is about to be run (this is case sensitive). Creates and returns a new C<CommandController> instance if the command if free to run. Dies if not. The C<IniData> reference is used to determine if Win32 extensions have been disabled. If this is the case then the check to see if this command is free to run is not done (since doing so relies on Win32 functionality).

=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
 All rights reserved.
 This component and the accompanying materials are made available
 under the terms of the License "Eclipse Public License v1.0"
 which accompanies this distribution, and is available
 at the URL "http://www.eclipse.org/legal/epl-v10.html".
 
 Initial Contributors:
 Nokia Corporation - initial contribution.
 
 Contributors:
 
 Description:
 

=cut

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
# Name    : NAB.pm
# Use     : Nokia Automated Build.


#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
# v1.3.2 (12/04/2006)
#  - Fixed sub argument parsing routine __ParseSubArguments where arguments were not
#    correctly mached.
#  - Updated argument parsing to allow use of single and double hyphens ('-' and '--').
#  - Updated code to use correct XMLManip::Node child access.
#
# v1.3.1 (07/02/2006)
#  - NAB display the version of the loaded modules. Modules must use ISIS templates.
#
# v1.3.0 (07/02/2006)
#  - Updated NAB to used HTTP Server with 'Logger2.pm'.
#
# v1.2.2 (24/01/2006)
#  - Fixed non found flags were printed before checking all patterns.
#  - Removed core module since it was never used.
#  - Updated help printout for NAB.
#
# v1.2.1 (16/01/2006)
#  - Added an extra hashtable to all steps for global data storage and sharing.
#  - Add -st|-showsteps, display steps by operation.
#  - My birthday (Wooohoooo).
#
# v1.1.1 (13/01/2006)
#  - Added eval block around step calls to assure correct script termination if error occurs.
#
# v1.1.0 (11/01/2006)
#  - Added support for 'resume' and 'step' operations.
#  - Added 'ExecuteResume' to the '__Operation' package.
#  - Added 'ExecuteSteps' to the '__Operation' package.
#
# v1.0.1 (10/01/2006)
#  - Added unused flag checking.
#  - Separated global arguments from operation arguments (see documentation).
#
# v1.0.0 (06/01/2006) - RELEASE CANDIDATE 1
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   NAB package.
#
#--------------------------------------------------------------------------------------------------
package NAB;

use strict;
use warnings;

use ISIS::ErrorDefs;
use ISIS::XMLManip;
use ISIS::Logger2;
use ISIS::Registry;
use ISIS::HttpServer;

# ISIS constants.
use constant ISIS_VERSION       => '1.3.2';
use constant ISIS_LAST_UPDATE   => '12/04/2006';
use constant ISIS_PERL_VERSION  => '5.6.1';
use constant DEBUG              => 0;

# Script constants.
use constant ROOT_SCRIPTS_DIR   => "\\isis_sw\\build_config\\";
use constant OPS_CONFIG_FILE    => ROOT_SCRIPTS_DIR."operations.xml";
use constant REG_CONFIG_FILE    => ROOT_SCRIPTS_DIR."registry.xml";

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new NAB( ", join(', ', @_), " )\n"  if(DEBUG);
  my ($class, @args) = (shift, @_);
  
  my $self = bless { _ops_cfg    => OPS_CONFIG_FILE,   # operations configuration file.
                     _reg_cfg    => REG_CONFIG_FILE,   # registry configuration file.
                     _target     => 'all',             # global target keyword.
                     _override   => 0,                 # override status.
                     _args       => \@args,            # passed arguments.
                     _gbl_mem    => {},                # global shared memory.
                     _resume     => undef,             # resume information.
                     _step       => undef              # step information.
                   }, $class;

  OUT2XML::SetXMLLogName("nab_main_log.html");
  OUT2XML::SetXMLLogVerbose("on");
  OUT2XML::SetXMLLogInterface( HttpServer::GetAddress()."/isis_interface" );
  OUT2XML::OpenXMLLog();
  OUT2XML::Header("Nokia Automated Build", "Started on ".scalar(localtime));

  $self->__ParseMainArguments();
  $self->__LoadConfigurationFiles();
  $self->__ParseSubArguments();
  $self->__LoadOperationSteps();
  
  return $self;
}

#--------------------------------------------------------------------------------------------------
# __ParseMainArguments - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __ParseMainArguments
{
  warn "NAB::__ParseArguments( ", join(', ', @_), " )\n" if(DEBUG);
  my ($self, @gblArgs, @subArgs) = (shift);
  
  while(defined($_ = shift @{$self->{_args}}))
  {
    if(/^--?(?:h|-h|help|-help)$/) { $self->__DisplayHelp();  OUT2XML::Die(0); }
    if(/^--?(?:st|-showsteps)$/)   { $self->__DisplaySteps(); OUT2XML::Die(0); }
    if(/^--?(?:ocf|opscfg)=(.+)$/) { $self->{_ops_cfg}  = $1; push @gblArgs, $_; next; }
    if(/^--?(?:rcf|regcfg)=(.+)$/) { $self->{_reg_cfg}  = $1; push @gblArgs, $_; next; }
    if(/^--?(?:tg|target)=(.+)$/)  { $self->{_target}   = $1; push @gblArgs, $_; next; }
    if(/^--?(?:r|resume)=(.+)$/)   { $self->{_resume}   = $1; push @gblArgs, $_; next; }
    if(/^--?(?:s|step)=(.+)$/)     { $self->{_step}     = $1; push @gblArgs, $_; next; }
    if(/^--?(?:or|override)$/)     { $self->{_override} =  1; push @gblArgs, $_; next; }

    push @subArgs, $_;
  }

  @{$self->{_gbl_args}} = @gblArgs;
  @{$self->{_args}}     = @subArgs;
  
  OUT2XML::OpenMainContent('Script Initialisation');

  if(scalar @{$self->{_args}} == 0)
  {
    OUT2XML::Error("No arguments passed to NAB. Type \'nab.pl --help\' for more information.");
    OUT2XML::Die(ERR::MISSING_SWITCH);
  }
  
  OUT2XML::OpenSummary("Nokia Automated Build Configuration");
  OUT2XML::SummaryElmt("Command line", 'nab.pl '.join(' ', (@{$self->{_gbl_args}}, @{$self->{_args}})));
  OUT2XML::SummaryElmt("operations configuration file", $self->{_ops_cfg});
  OUT2XML::SummaryElmt("registry configuration file", $self->{_reg_cfg});
  OUT2XML::SummaryElmt("operation target", "\'".$self->{_target}."\'");
  OUT2XML::SummaryElmt("override activated (missing modules will be ignored)") if($self->{_override});
  OUT2XML::CloseSummary();
}

#--------------------------------------------------------------------------------------------------
# __ParseSubArguments - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __ParseSubArguments
{
  warn "NAB::__ParseSubArguments( ", join(', ', @_), " )\n" if(DEBUG);
  my ($self, $mainFlags, $currentFlag, %patterns, %inputs, %mandatory) = (shift);

  $mainFlags = join('|', $self->{_ops_data}->ChildTypes()); 

  foreach my $op (@{$self->{_ops_data}->Childs()})
  { # determine flag patterns for each op.
    push @{$patterns{$op->Type()}}, @{$op->Child('flag')};
    
    foreach my $step (@{$op->Child('step')})
    { push @{$patterns{$op->Type()}}, @{$step->Child('flag')}; } 
  }
  
  foreach my $arg (@{$self->{_args}})
  { # determine arguments for each op.
    if($arg =~ /^-($mainFlags)$/)
    {
      $currentFlag = $1;
      $inputs{$currentFlag} = [];
      push @{$self->{_exec}}, $self->{_ops_data}->Child($1, 0);
    }
    else
    {
      push @{$inputs{$currentFlag}}, $arg;
    }
  }

  my $hasError = 0;
  foreach my $op (sort keys %inputs)
  {
    foreach my $flagNode (@{$patterns{$op}})
    {
      my $pattern = $flagNode->Attribute('pattern');
      my $type    = $flagNode->Attribute('type');
      my $input   = undef;

      $pattern =~ s/^-([^=]+)/-\($1\)/;
      $pattern = qr($pattern);

      $mandatory{$op}{$1} = 0 if($type eq 'mandatory');
  
      if($type !~ /^(?:mandatory|optional)$/)
      {
        OUT2XML::Error("Flag \'<b>", $pattern, "</b>\' is of illegal type \'<b>",
                       $type, "</b>\'. Should be \'optional\' or \'mandatory\'"
                      );
        $hasError = 1;
      }
      
      my $i = 0;
      foreach $input (@{$inputs{$op}})
      {
        if($input =~ /^$pattern$/)
        {
          $self->{_ops_args}{$op}{$1} = $2 || 1;
          $mandatory{$op}{$1} = 1;
          splice(@{$inputs{$op}}, $i, 1);
        }
        ++$i;
      }
    }

    foreach my $input (@{$inputs{$op}})
    {
      OUT2XML::Error("Flag \'<b>${input}</b>\' does not exist");
      $hasError = 1;
    }
  }

  foreach my $op (sort keys %mandatory)
  {
    foreach my $flag (sort keys %{$mandatory{$op}})
    {
      unless($mandatory{$op}{$flag})
      {
        OUT2XML::Error("Mandatory flag \'<b>", $flag, "</b>\' for operation \'<b>", 
                       $op, "</b>\' was not defined."
                      );
        $hasError = 1;
      }
    }
  }

  if($hasError)
  {
    OUT2XML::Die(ERR::MISSING_SWITCH);
  }
  else
  {
    OUT2XML::Print("<b>Passed arguments :</b>\n");
    foreach my $op (sort keys %{$self->{_ops_args}})
    {
      foreach my $switch (sort keys %{$self->{_ops_args}{$op}})
      {
        OUT2XML::Print(" - $switch set to \'".$self->{_ops_args}{$op}{$switch}."\'\n");
      }
    }
  }
}

#--------------------------------------------------------------------------------------------------
# __LoadConfigurationFiles - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __LoadConfigurationFiles
{
  warn "NAB::__LoadOperationsCfg( ", join(', ', @_), " )\n" if(DEBUG);
  my ($self) = (shift);
  
  $self->{_ops_data} = &XMLManip::ParseXMLFile($self->{_ops_cfg}, XMLManip::NO_LOCK);
  $self->{_reg_data} = new Registry($self->{_reg_cfg}, { error_level => 1 });
  
  foreach my $includeNode (@{$self->{_ops_data}->Child('perl_include')})
  {
    push @INC, $includeNode->Attribute('path');
    $self->{_ops_data}->RemoveChild($includeNode);
  } 
}

#--------------------------------------------------------------------------------------------------
# _LoadOperationSteps - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __LoadOperationSteps
{
  warn "NAB::__LoadOperationSteps( ", join(', ', @_), " )\n" if(DEBUG);
  my ($self, $hasError) = (shift, 0);

  foreach my $opNode (@{$self->{_exec}})
  {
    push @{$self->{_ops}}, __Operation->new($opNode, $self);
  }

  OUT2XML::CloseMainContent();
}

#--------------------------------------------------------------------------------------------------
# __CheckConcurrentStep - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __CheckConcurrentStep
{
  warn "NAB::__CheckConcurrentStep( ", join(', ', @_), " )\n" if(DEBUG);
  my ($self, $opNode, $stepNode1) = (shift, shift, shift);
  
  foreach my $stepNode2 (@{$opNode->Child('step')})
  {
    next if($stepNode1 == $stepNode2 or
            $stepNode1->Attribute('id') ne $stepNode2->Attribute('id') or
            $stepNode2->Attribute('target') !~ /^(?:all|$self->{_target})$/i);

    my ($target1, $target2) = ($stepNode1->Attribute('target'), $stepNode2->Attribute('target'));
    
    if($target1 =~ /^$target2$/i or 'all' =~ /^(?:$target1|$target2)$/i)
    {
      my $infoNode1 = $stepNode1->Child('info', 0);
      my $infoNode2 = $stepNode2->Child('info', 0);
      my $info1 = $infoNode1 && $infoNode1->Content() || 'No description available';
      my $info2 = $infoNode2 && $infoNode2->Content() || 'No description available';
      
      OUT2XML::Error("Operation <b>".$opNode->Type()."</b> - Found conflicting steps :\n".
                     "Step \'<b>".$info1."</b>\' has id <b>".$stepNode1->Attribute('id').
                     "</b> and target <b>".$target1."</b>.\n".
                     "Step \'<b>".$info2."</b>\' has id <b>".$stepNode2->Attribute('id').
                     "</b> and target <b>".$target2."</b>.\n"
                    );

      return 1;
    }
  }
  
  return 0;
}

#--------------------------------------------------------------------------------------------------
# __DisplayHelp - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __DisplayHelp
{
  my ($self) = (shift);
  
  if(not defined $self->{_ops_data} and not defined $self->{_reg_data})
  { $self->__LoadConfigurationFiles(); }
  
  OUT2XML::OpenMainContent('NAB Help Information');
  OUT2XML::Print("<b>nab.pl</b> - Nokia Automated Build - v".ISIS_VERSION." (".ISIS_LAST_UPDATE.")\n");
  OUT2XML::Print("usage : nab.pl [-help] [-st] [-target=xxx] [-OP1_FLG] [-OP1_ARG1 [-OP1_ARG2 ...]] [-OP2_FLG [-OP2_ARG1 [-OP2_ARG2 ...]]]\n");

  OUT2XML::Print("\nFlags:\n");
  OUT2XML::Print("\t-help\tShow this help message.\n");
  OUT2XML::Print("\t-st\tList steps available by command flag.\n");
  
  OUT2XML::Print("\nCommands:\n");
  foreach my $op (@{$self->{_ops_data}->Childs()})
  {
    OUT2XML::Print("<b>", $op->Type(), "</b> : <i>", $op->Attribute('title')||"", "</i>\n");
    if(@{$op->Child('info')})
    {
      foreach my $info (@{$op->Child('info')})
      {
        chomp(my $line = $info->Content());
        $line =~ s/^\s*//g;
        $line = "\t".$line; $line =~ s/\s*\n\s*/\n\t/g;
        OUT2XML::Print($line,"\n");
      }
    }
    else
    {
      OUT2XML::Print("No information available for this operation.\n"); 
    }
    
    OUT2XML::Print(" + Flags:\n");
    if(@{$op->Child('flag')})
    {
      foreach my $f (@{$op->Child('flag')})
      {
        my $fill = "\t\t";
        OUT2XML::Print($fill,$f->Attribute('pattern'),$fill,$f->Attribute('info')," [",$f->Attribute('type'),"]\n");
      }
    }

    OUT2XML::Print("\n");
  }
  
  OUT2XML::CloseMainContent();
}

#--------------------------------------------------------------------------------------------------
# __DisplaySteps - PRIVATE.
#--------------------------------------------------------------------------------------------------
sub __DisplaySteps
{
  my ($self) = (shift);
  
  if(not defined $self->{_ops_data} and not defined $self->{_reg_data})
  { $self->__LoadConfigurationFiles(); }
  
  OUT2XML::OpenMainContent('NAB Help Information');
  OUT2XML::Print("<b>nab.pl</b> - Nokia Automated Build - v".ISIS_VERSION." (".ISIS_LAST_UPDATE.")\n");
  foreach my $op (@{$self->{_ops_data}->Childs()})
  {
    OUT2XML::Print("\n");
    OUT2XML::Print("<b>", $op->Type(), "</b> : <i>", $op->Attribute('title')||"", "</i>\n");
    if(@{$op->Child('step')})
    {
      foreach my $s (@{$op->Child('step')})
      {
        # calculate heading space
        my $info = "";
        foreach my $i (@{$s->Child('info')}) {$info.= $i->Content()||"";}
        OUT2XML::Print("\t",$s->Attribute('id'),"\t",$info,"\n");
      }
    }     
  }
  OUT2XML::CloseMainContent();
}

#--------------------------------------------------------------------------------------------------
# Public member subroutines.
#--------------------------------------------------------------------------------------------------
sub Execute
{
  warn "NAB::Execute( ", join(', ', @_), " )\n"  if(DEBUG);
  my $self = shift;
  
  OUT2XML::OpenMainContent("Modules Version");
  OUT2XML::OpenEvent("Modules Version");
  foreach my $operation ( @{$self->{_ops}} )
  {
    $operation->LogStepVersion();
  }
  OUT2XML::CloseEvent();
  OUT2XML::CloseMainContent();
  
  if ( $self->{_resume} )
  {
    # Manage only one operation
    my $operation = $self->{_ops}[0];
    OUT2XML::OpenMainContent(ucfirst($operation->Type())." Operation");
    $operation->ExecuteResume($self->{_resume}, $self->{_target},
                              $self->{_ops_args}{$operation->Type()},
                              $self->{_reg_data},
                              $self->{_gbl_mem});
    OUT2XML::CloseMainContent();
  }
  elsif ( $self->{_step} )
  {
    # Manage only one operation
    my $operation = $self->{_ops}[0];
    OUT2XML::OpenMainContent(ucfirst($operation->Type())." Operation");
    $operation->ExecuteSteps($self->{_step}, $self->{_target},
                             $self->{_ops_args}{$operation->Type()},
                             $self->{_reg_data},
                             $self->{_gbl_mem});
    OUT2XML::CloseMainContent();
  }
  else
  {
    # Normal execution of operation.
    foreach my $operation ( @{$self->{_ops}} )
    {
      OUT2XML::OpenMainContent(ucfirst($operation->Type())." Operation");
      $operation->Execute($self->{_target},
                          $self->{_ops_args}{$operation->Type()},
                          $self->{_reg_data},
                          $self->{_gbl_mem});
      OUT2XML::CloseMainContent();
    }
  }
  
  OUT2XML::Footer("Finished on ".scalar(localtime), "Log file generated by Logger2 v".Logger2::ISIS_VERSION);
  OUT2XML::CloseXMLLog();
}

1;

#--------------------------------------------------------------------------------------------------
#
#   __Operation package.
#
#--------------------------------------------------------------------------------------------------
package __Operation;

sub new
{
  my ($class, $opNode, $nab, $hasError, @steps) = (shift, shift, shift, 0);

  foreach my $stepNode (@{$opNode->Child('step')})
  {
    if($stepNode->Attribute('target') =~ /^(?:all|$nab->{_target})$/i)
    {
      $hasError |= $nab->__CheckConcurrentStep($opNode, $stepNode);
      my $step = __Step->new($opNode, $stepNode, $nab);
      $hasError |= 1 unless($step->IsValid() or $nab->{_override});
      push @steps, $step;
    }
  }
  
  my $infoNode = $opNode->Child('info', 0);
  my $info     = $infoNode && $infoNode->Content() || 'No information available';

  OUT2XML::Die(ERR::INVALID_CFG_STEP) if($hasError);

  bless { '__Operation::Type'  => $opNode->Type(),
          '__Operation::Steps' => \@steps,
          '__Operation::Info'  => $info,
        }, $class;
}

sub LogStepVersion
{
  my ($self) = (shift);
  foreach my $step ( @{$self->{'__Operation::Steps'}} )
  {
    $step->LogStepVersion();
  } 
  
}

sub ExecuteResume
{
  my ($self, $from) = (shift, shift);
  foreach my $step ( @{$self->{'__Operation::Steps'}} )
  {
    $step->Execute(@_) if($step->IsValid() and $step->Id() ge $from);
  } 
}

sub ExecuteSteps
{
  my ($self, $stepstring) = (shift, shift);
  my $steps = join('|', split('\s+', $stepstring));
  foreach my $step ( @{$self->{'__Operation::Steps'}} )
  {
    $step->Execute(@_) if($step->IsValid() and $step->Id() =~ /^(?:$steps)$/);
  } 
}

sub Execute
{
  my $self = shift;

  foreach my $step (@{$self->{'__Operation::Steps'}})
  {
    $step->Execute(@_) if($step->IsValid());
  } 
}

sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
  
  $self->{$method} = shift if @_;
  return $self->{$method};
}

1;

#--------------------------------------------------------------------------------------------------
#
#   __Step package.
#
#--------------------------------------------------------------------------------------------------
package __Step;

sub new
{
  my ($class, $opNode, $stepNode, $nab, $isValid) = (shift, shift, shift, shift, 1);

  my $callNode = $stepNode->Child('call', 0);
  my $call     = $callNode && $callNode->Content() || 'undefined';
  
  my $infoNode = $stepNode->Child('info', 0);
  my $info     = $infoNode && $infoNode->Content() || 'No information available';

  my $stepId   = $stepNode->Attribute('id') || 'undefined';
  my $critical = $stepNode->Attribute('critical') || 'no';
  
  if($stepId eq 'undefined')
  {
    OUT2XML::Error("Step \'<b>".$info."</b>\' with id <b>".$stepId."</b> is invalid :\n".
                   "No id attribute specified.");
    $isValid = 0;
  }
  
  if($call eq 'undefined')
  {
    OUT2XML::Error("Step \'<b>".$info."</b>\' with id <b>".$stepId."</b> is invalid :\n".
                   "No call information was found.");
    $isValid = 0;
  }
  
  if($critical !~ /^(?:yes|no)$/i)
  {
    OUT2XML::Error("Step \'<b>".$info."</b>\' with id <b>".$stepId."</b> is invalid :\n",
                   "The specified critical attribute should be \'yes\' or \'no\', and not \'$critical\'.");
    $isValid = 0; 
  }
  else
  {
    $critical = ($critical =~ /^yes$/i) || 0; 
  }
  
  my ($module, $subroutine);

  if(($module, $subroutine) = ($call =~ /^(.+?)::(.+?)$/))
  {
    if(eval 'require '.$module.';')
    {
      push @{$nab->{_usermodules}}, $module;
      unless(exists &{$module.'::'.$subroutine})
      {
        if($nab->{_override})
        {
          OUT2XML::Warning("Operation <b>".$opNode->Type()."</b>, step \'<b>".$info."</b>\' (id <b>".$stepId."</b>) :\n".
                           "Unable to find subroutine <b>".$subroutine."</b> in module <b>".$module.".pm</b>. ".
                           "Step will be removed due to <i>-override</i> flag.");
        }
        else
        {
          OUT2XML::Error("Operation <b>".$opNode->Type()."</b>, step \'<b>".$info."</b>\' (id <b>".$stepId."</b>) :\n".
                         "Unable to find subroutine <b>".$subroutine."</b> in module <b>".$module.".pm</b>. ".
                         "Please verify subroutine name in <b>".$nab->{_ops_cfg}."</b> operation file.");
        }
        $isValid = 0;
      }
    }
    else
    {
      if($nab->{_override})
      {
        OUT2XML::Warning("Operation <b>".$opNode->Type()."</b>, step \'<b>".$info."</b>\' (id <b>".$stepId."</b>) :\n".
                         "Unable to load module <b>".$module.".pm</b>. ".
                         "Step will be removed due to <i>-override</i> flag.\n$@");
      }
      else
      {
        OUT2XML::Error("Operation <b>".$opNode->Type()."</b>, step \'<b>".$info."</b>\' (id <b>".$stepId."</b>) :\n".
                       "Unable to load module <b>".$module.".pm</b>. ".
                       "Please verify module name in <b>".$nab->{_ops_cfg}."</b> operation file.\n$@");
      }
      $isValid = 0;
    }
  }
  else
  {
    OUT2XML::Error("Operation <b>".$opNode->Type()."</b>, step \'<b>".$info."</b>\' (id <b>".$stepId."</b>) :\n".
                   "Call pattern is invalid. Should be <i>module::subroutine</i>.\n".
                   "Please verify step call in <b>".$nab->{_ops_cfg}."</b> operation file.");
    $isValid = 0; 
  }

  my $moduleVersion = undef;
  if ( $isValid )
  {   
      eval{ $moduleVersion = $module->ISIS_VERSION; };
  }

  bless { '__Step::Id'         => $stepId,
          '__Step::IsCritical' => $critical,
          '__Step::Info'       => $info,
          '__Step::IsValid'    => $isValid,
          '__Step::Module'     => $module,
          '__Step::Subroutine' => $subroutine,
          '__Step::Version'    => $moduleVersion,
        }, $class;
}

sub LogStepVersion
{
  my $self = shift;
  OUT2XML::Print("<b>", $self->Module(), "</b> version is <b>", $self->Version(), "</b>\n");
}

sub Execute
{
  my $self = shift;
  
  OUT2XML::OpenEvent("Step ".$self->{'__Step::Id'}." : ".$self->{'__Step::Info'});
  my $function = \&{$self->{'__Step::Module'}.'::'.$self->{'__Step::Subroutine'}};
  
  eval { &{$function}(@_); };
  
  if($@)
  {
    if($self->{'__Step::IsCritical'})
    {
      OUT2XML::Error($@);
      OUT2XML::Die(ERR::CRITICAL_STEP_FAILED);
    }
    else
    {
      OUT2XML::Warning($@);
    }
  }
  
  OUT2XML::CloseEvent();
}

sub AUTOLOAD
{
  my ($self, $method) = (shift, our $AUTOLOAD);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
  
  $self->{$method} = shift if @_;
  return $self->{$method};
}

1;

__END__

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

NAB - Nokia Automated Build System.

=head1 USER INFORMATION

=head2 Description :

This module is used to execute complex build operations, and allow easy configuration of
specific steps by the use of independant modules, allowing therefor to configure several
builds and other operations with the same configuration files.

=head2 Main NAB Arguments :

=over 1

=item * '-ocf=FILE' or '-opscfg=FILE'

This allows the user to specify what XML configuration file to use for determining
build steps and modules to use. By default, this value is set to 'operations.xml'.
For more information on how to format the content of this configuration file, see
L<Operations Configuration File>.

=item * '-rcf=FILE' or '-regcfg=FILE'

This allows the user to specify what XML registry file to use for defining
build data such as names and supported products. By default, this value is set to
'registry.xml'. For more information on how to format the content of this configuration
file, see L<Registry Configuration File>.

=item * '-cm=FILE' or '-coremodule=FILE' :

This defines the core module to be used. This module is used when looking up
a function call that isn't specified with a module. By default, the module name
is set to 'corebuild.pm'.

=item * '-tg=TARGET' or '-target=TARGET' :

Sets the target of the operation. Steps in the operations XML configuration can specify
a target attribute that will define when the corresponding step must be executed based
on the target value passed as an argument to the script using this flag.

=item * '-or' or '-override' :

This defines the action to take when a step is missing its corresponding module. Without
the 'override' flag, a missing module or function in a specified module will rase an
error and terminate the script before it executes any operations. If the flag is defined,
a missing module or function will only generate a warning and the corresponding step will
be skipped.

=back

=head2 Operations Configuration File :

This file contains all information regarding the different operations that NAB can execute.
It is directly used by NAB to determine operation steps, operation flags, and necessary
modules. It must be configured using the following syntax.

  <operations>
  
    <operation_flag>
  
      <info>...<info>
  
      <flag type="..." pattern="..." info="..." />
      
      <step id="..." target="...">
        <call>...</call>
        <info>...</info>
        <flag type="..." pattern="..." info="..." />
      </step>
  
    </operation_flag>
  
  </operations>

the <operations> root node is mandatory. All childs of this node (ie: <operation_flag>)
can have any valid xml tag name, and will define the operation flag to pass to the NAB
instance to execute it.

The step nodes in each <operation_flag> node defines a step and must have at least the 'id'
attribute defined. If the 'target' attribute is not defined, it's value will default to 'all'.

For an operation node or a step node, it is possible to define an <info> node that contains a
description of the action performed by the containing node. It is optional but strongly
recommended since it clarifies what the operation or step does for further references.

Finally, one or several <flag> nodes can be defined, each of them having at least both
attributes 'type' and 'pattern' defined. The type determines wether the flag is 'optional'
or 'mandatory' and the pattern corresponds to the perl regular expression that the passed
arguments must be tested with, eventually having a captured value (ie: '-flag=(.*)'). An
'info' attribute can be specified to explain the use of the flag.

=head2 Registry Configuration File :

The registry configuration file is parsed using the L<ISIS::ConfigsData> package. It contains
all static information that will be passed to all called functions for each operation. This
file should respect the syntax specified in the L<ISIS::ConfigsData> documentation.

=head1 DEVELOPER INFORMATION

=head2 NAB Internal Data Structure :

A NAB Instance is a blessed hash table containing the following data :

=over 1

=item * _ops_cfg

This is the operations' configuration file. By default set to OPS_CONFIG_FILE defined
as a constant at the beginning of this file. This XML file contains all steps, generic
or specific, all flags, and all necessary modules for a given operation.

=item * _bld_cfg

This is the builds' configuration file. By default set to REG_CONFIG_FILE defined
as a constant at the beginning of this file. This XML file contains all necessary
information for each type of build possible.

=item * _ops_data

This L<ISIS::XMLManip::Node> reference is the XML tree resulting from the operations' configuraiton
file set in L<_ops_cfg>. See L<ISIS::XMLManip::Node> for more information.

=item * _reg_data

This L<ISIS::XMLManip::Node> reference is the XML tree resulting from the builds' configuraiton
file set in L<_bld_cfg>. See L<ISIS::XMLManip::Node> for more information.

=item * _target

This is the only general value passed on to all possible operations. It is by default set
to 'all' and every step not defining the target attribute will be set to this value as well.
This value is used to filter out irrelevant steps in a given operation. If an other value
than 'all' is specified, every step targeting this specific value will be called in addition
to the steps defined for the 'all' target. On the other hand, when the 'all' target is
defined, only steps defined for the 'all' target will be called.

=item * _override

This value is used to determine wether the script should halt when encountering a missing
module required by a function call, or just ignore it after printing out a warning. By
default, this value is set to '0' and must be activated by having the user pass the
'-override' flag to the script.

=item * _gbl_args

This array contains all global arguments that are used to define configuration files, the
general script target and override. For more information on theses flags, see L<Main NAB Arguments>

=item * _args

This value holds a reference to an array containing all dynamic flags. This means it will
only contain operation flags and their passed on flags. All flags allowing to define NAB
specific components (such as configuration files) will be stripped out.

=item * _ops_args

This is a hash table of hash tables containing the parsed information necessary for each
operation. Its structure is as follows :

  %_ops_args
    |
    -- %op_type
         |
         -- %flag
              |
              -- value

For example, a call to $self->{_ops_args}{build}{wa} will return the value of the flag wa for
the build operation. For boolean flags, the returned value is 1 if set, 0 otherwise.

=item * _exec

This array contains a reference to L<ISIS::XMLManip::Node> objects corresponding to the operations
the user has decided to execute. The array is populated during the subroutine call 
L<NAB::__ParseSubArguments>. See L<ISIS::XMLManip::Node> for more information on this package.

=item * _ops

This array contains L<__Operation> objects in the order they must be called. This array is
populated in the subroutine L<NAB::__LoadOperationSteps>. See L<__Operation> for more
information on this package.

=item * _gbl_mem

This hash table contains all shared resources and data between the different steps. This space
is to be used by module developpers to communicate information between different subroutine
calls and modules.

=back

=head2 NAB INTERFACE

=head2 __Operation PACKAGE

The __Operation package contains all information regarding a specific operation to execute.
One instance is created for each main operation the user wants to execute, and are created
directly when the NAB package is instanciated. This package provides a unique public 
subroutine L<__Operation::Execute> that is automatically called when the L<NAB> instance. There
is a default accessor for all information contained in a __Operation instance, but it is not
used throughout the script.

=over 1

=item * __Operation( <OPERATION_NODE>, <NAB_INSTANCE> ) :

The constructor takes the L<XMLManip::Node> operation node, and the L<NAB> instance it is
attached to. This call will also create all L<__Step> instances corresponding to this operation.

=item * Execute(  ) :

This will execute the full operation and call sequentially L<__Step::Execute> on all contained
steps for this operation. For more information on the step execution, see L<__Step::Execute>.

=back

=head2 __Step PACKAGE

The __Step package contains all information regarding a specific step for a given operation.
All instances of this package are contained by an instance of the L<__Operation> that contains
all information regarding a specific operation. See L<__Operation> for more information. The step
package provides a unique public subroutine L<__Step::Execute> that is automatically called by
the L<__Operation> instance it is contained by. There is a default accessor for all information
contained in a __Step instance, but it is not used throughout the script.

=over 1

=item * __Step( <OPERATION_NODE>, <STEP_NODE>, <NAB_INSTANCE> ) :

The constructor takes the L<XMLManip::Node> operation node the step is attached to, the
corresponding L<XMLManip::Node> for the step, and the L<NAB> instance all this is attached to.
This call will create a new instance and check the existance of the necessary module and
subroutine. The necessary module will also be loaded.

=item * Execute(  ) :

This will actually execute the step by calling the corresponding subroutine from the defined
module. The function will be passed all build information, taken from the builds' configuraiton
file, and the operation's arguments that were passed along with the operation target. For more
information on the builds' configuration file, see L<Configs Configuration File>.

=back

=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------

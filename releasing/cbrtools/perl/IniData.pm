# Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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

package IniData;

use strict;
use FindBin;
use File::Path;
use File::Spec;
use Utils;
use PathData;

our $cache = {}; # Persistent (private) cache

$|++;

#
# Constants.
#

my $iniName = \ 'reltools.ini';
my $envDir = undef; # only filled in when we do New()
my $binDir = \ "$FindBin::Bin\\";
my @standardIgnores = ('\\epoc32\\build\\*',
           '\\epoc32\\wins\\c\\*',
           '\\epoc32\\winscw\\c\\*',
           '\\epoc32\\release\\*.ilk',
           '\\epoc32\\release\\*.bsc',
           '\\epoc32\\data\\emulator\\*.sys.ini',
           '\\epoc32\\release\\tools\\*',
           '\\epoc32\\release\\tools2\\*'
          );

# Support for target alias file
use constant CBR_TARGET_ALIAS_LOCATION => scalar "\\epoc32\\tools\\variant\\";

#
# Constructor
#

sub New {
  my $pkg = shift;  
  my $filename = shift;
  my $ignoreepocroot = shift;

  if ( defined ($ENV{EPOCROOT}) or ! $ignoreepocroot ){
     $envDir = \ Utils::PrependEpocRoot("\\epoc32\\relinfo\\");
  }
  
  my $self = {};
  
  $self->{warnIniLocation} = 0;
  # Support for target alias file
  # This is a persistant flag.
  # If set then a warning must be printed if either HasTargetPlatforms()
  # or TargetPlatforms() is used. The flag is then cleared thus the warning is a one off.
  # If clear this is because the cbrtargetsalias.cfg file has been found
  # or the no_target_alias_warning flag is set in reltools.ini
  $self->{mustWarnTargetAliasLocation} = 1;
  if (defined $filename and -e $filename ) {
    $self->{iniFileName} = $filename;
  } elsif (defined $$envDir and -e "$$envDir$$iniName" ) {
    $self->{iniFileName} = "$$envDir$$iniName";
  } elsif (-e "$$binDir$$iniName") {
    $self->{warnIniLocation} = 1;
    $self->{iniFileName} = "$$binDir$$iniName";
  } else {
    my $msg = "Error: \"$$iniName\" not found in ";
    $msg = $msg."either \"$$envDir\" or " if ( defined ($$envDir));
    $msg = $msg."\"$$binDir\"\n";
    die $msg;
  }

  if ($cache->{lc($self->{iniFileName})}) {           
    return $cache->{lc($self->{iniFileName})};
  }

  foreach my $thisIgnore (@standardIgnores) {
    push (@{$self->{binIgnore}}, $thisIgnore);
  }

  bless $self, $pkg; # $self isn't blessed until we know we need it

  $self->ReadIni();

  # Support for target alias file
  if (!$ignoreepocroot) {
    $self->{targetAliasName} = Utils::PrependEpocRoot(CBR_TARGET_ALIAS_LOCATION).'cbrtargetalias.cfg';

    if ($self->ReadTargetAliasFile == 1) {
      # Successful read so clear the warning flag
      $self->{mustWarnTargetAliasLocation} = 0;
    }
  }

  $cache->{lc($self->{iniFileName})} = $self;

  return $self;
}

#
# Public
#

sub DiffTool {
  my $self = shift;
  unless (exists $self->{diff_tool}) {
    return undef;
  }
  return $self->{diff_tool};
}

sub RequireInternalVersions {
  my $self = shift;
  if (exists $self->{require_internal_versions}) {
    return 1;
  }
  return 0;
}

sub IgnoreSourceFilterErrors {
  my $self = shift;
  if (exists $self->{ignore_source_filter_errors}) {
    return 1;
  }
  return 0;
}

sub RemoteSiteType {
  my $self = shift;

  unless (exists $self->{remote_site_type}) {
    $self->{remote_site_type} = 'FTP';
  }
  elsif ($self->{remote_site_type} =~ /(network|drive)/i) {
    $self->{remote_site_type} = 'NetDrive';
  }
  elsif ($self->{remote_site_type} =~ /experimentalproxy/i) {
    $self->{remote_site_type} = 'FTP::Proxy::Experimental';
  }
  elsif ($self->{remote_site_type} =~ /experimentalftp/i) {
    $self->{remote_site_type} = 'FTP::Experimental';
  }
  elsif ($self->{remote_site_type} =~ /multivolumeexport/i) {
    $self->{remote_site_type} = 'NetDrive::MultiVolumeExport';
  }
  elsif ($self->{remote_site_type} =~ /multivolumeimport/i) {
    $self->{remote_site_type} = 'NetDrive::MultiVolumeImport';
  }
  elsif ($self->{remote_site_type} =~ /proxy/i) {
    $self->{remote_site_type} = 'FTP::Proxy';
  }  
  else {
    $self->{remote_site_type} = 'FTP';
  }
  return $self->{remote_site_type};
}

sub RemoteHost {
  my $self = shift;
  unless (exists $self->{remote_host}) {
    return undef;
  }
  return $self->{remote_host};
}

sub RemoteUsername {
  my $self = shift;
  unless (exists $self->{remote_username}) {
    return undef;
  }
  return $self->{remote_username};
}

sub RemotePassword {
  my $self = shift;
  unless (exists $self->{remote_password}) {
    return undef;
  }
  return $self->{remote_password};
}

sub RemoteLogsDir {
  my $self = shift;
  unless (exists $self->{remote_logs}) {
    return undef;
  }
  return $self->{remote_logs};
}

sub Proxy {
  my $self = shift;
  unless (exists $self->{proxy}) {
    return undef;
  }
  return $self->{proxy};
}

sub ProxyUsername {
  my $self = shift;
  unless (exists $self->{proxy_username}) {
    return undef;
  }
  return $self->{proxy_username};
}

sub ProxyPassword {
  my $self = shift;
  unless (exists $self->{proxy_password}) {
    return undef;
  }
  return $self->{proxy_password};
}

sub PasvTransferMode {
  my $self = shift;
  if (exists $self->{pasv_transfer_mode}) {
    return 1;
  }
  return 0;
}

sub FtpServerSupportsResume {
  my $self = shift;
  if (defined $_[0]) {
    $self->{ftp_server_supports_resume} = $_[0];
  }
  if (exists $self->{ftp_server_supports_resume}) {
    return $self->{ftp_server_supports_resume} ? 1 : 0;
  }
  return 0;
}

sub FtpTimeout {
  my $self = shift;
  unless (exists $self->{ftp_timeout}) {
    return undef;
  }
  return $self->{ftp_timeout};
}

sub FtpReconnectAttempts {
  my $self = shift;
  unless (exists $self->{ftp_reconnect_attempts}) {
    return undef;
  }
  return $self->{ftp_reconnect_attempts};
}

sub TempDir {
  my $self = shift;
  if (exists $self->{temp_dir}) {
    return $self->{temp_dir};
  }
  return undef;
}

sub MaxExportVolumeSize {
  my $self = shift;
  if (exists $self->{max_export_volume_size}) {
    return $self->{max_export_volume_size};
  }
  else {
    return 639 * 1024 * 1024;
  }
}

sub PgpTool {
  my $self = shift;

  unless (exists $self->{pgp_tool}) {
    $self->{pgp_tool} = 'PGP';
  }
  elsif ($self->{pgp_tool} =~ /(gpg|gnupg)/i) {
    $self->{pgp_tool} = 'GPG';
  }
  else {
    $self->{pgp_tool} = 'PGP';
  }
  return $self->{pgp_tool};
}

sub PgpEncryptionKeys {
  my $self = shift;
  unless (exists $self->{pgp_encryption_keys}) {
    return [];
  }
  return $self->{pgp_encryption_keys};
}

sub PgpConfigPath {
  my $self = shift;
  unless (exists $self->{pgp_config_path}) {
    return undef;
  }
  return $self->{pgp_config_path};
}

sub ExportDataFile {
  my $self = shift;
  unless (exists $self->{export_data_file}) {
    die "Error: export_data_file keyword not specified in reltools.ini\n";
  }
  return $self->{export_data_file};
}

sub PathData {
  my $self = shift;
  unless (defined $self->{pathData}) {
    $self->{pathData} = PathData->New($self->{verbose});
  }
  return $self->{pathData};
}

sub HtmlNotes {
  my $self = shift;
  return (exists $self->{html_notes});
}

sub FromMapping {
  my $self = shift;
  my @fromMapping;

  if(defined @{$self->{from_mapping}}){
    @fromMapping = @{$self->{from_mapping}};
  }

  return @fromMapping;
}

sub ToMapping {
  my $self = shift;
  my @toMapping;

  if(defined @{$self->{to_mapping}}){
    @toMapping = @{$self->{to_mapping}};
  }

  return @toMapping;
}

sub HasMappings {
  my $self = shift;
  my $result = 0;

  if(defined @{$self->{from_mapping}} && defined @{$self->{to_mapping}} && Utils::SourceRoot() eq "\\"){
    $result = 1;
  }

  return $result;
}

sub PerformMapOnFileName {
  my $self = shift;
  my $operand = shift;

  my @fromMapping = $self->FromMapping();
  my @toMapping  = $self->ToMapping();
  my $fromMappingSize = @fromMapping;

  unless($operand =~ /^\\.*/) {
    $operand = "\\"."$operand";  # Add a \\ to the beginning, which is equal to srcroot.
  }

  if(@fromMapping) {
    for(my $position = 0; $position<$fromMappingSize; $position++) {
      if($operand =~ /^\Q$fromMapping[$position]\E/i){
        $operand =~ s/^\Q$fromMapping[$position]\E/$toMapping[$position]/i;
        last;
      }
    }
  }

  return $operand;
}

sub PerformReverseMapOnFileName {
  my $self = shift;
  my $operand = shift;

  my @fromMapping = $self->FromMapping();
  my @toMapping  = $self->ToMapping();
  my $toMappingSize = @toMapping;

  unless($operand =~ /^\\(.*)/) {
    $operand = "\\"."$operand";  # Add a \\ to the beginning, which is equal to srcroot.
  }

  if(@toMapping) {
    for(my $position = 0; $position<$toMappingSize; $position++) {
      if($operand =~ /^\Q$toMapping[$position]\E/i){
        $operand =~ s/^\Q$toMapping[$position]\E/$fromMapping[$position]/i;
        last;
      }
    }
  }

  return $operand;
}

sub CheckFileNameForMappingClash {
  my $self = shift;
  my $fileName = shift;

  my @toMapping  = $self->ToMapping();
  my $dirName;

  if($fileName =~ /^(.*)\\/) {
    $dirName = $1;
  }

  if(@toMapping) {
    foreach my $toMap (@toMapping) {
      if($dirName =~ /^\Q$toMap\E/i) {
        die "ERROR: Clash in mappings. The local mapping $toMap clashes with the source directory $dirName.\n";
      }
    }
  }
}

sub RemoteSite {
  my $self = shift;
  my $verbose = shift;
  unless (defined $self->{remoteSite}) {
    my $module = 'RemoteSite::'.$self->RemoteSiteType();
    eval "require $module";
    $self->{remoteSite} = $module->New(host => $self->RemoteHost(),
               username => $self->RemoteUsername(),
               password => $self->RemotePassword(),
               passive_mode => $self->PasvTransferMode(),
               resume_mode => $self->FtpServerSupportsResume(),
               proxy => $self->Proxy(),
               proxy_username => $self->ProxyUsername(),
               proxy_password => $self->ProxyPassword(),
               max_export_volume_size => $self->MaxExportVolumeSize(),
               verbose => $verbose);
    die "Failed to create remote site object" unless ref $self->{remoteSite};
  }
  return $self->{remoteSite};
}

sub LocalArchivePath {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub RemoteArchivePath {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub ArchivePathFile {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub ListArchiveComponents {
  require Carp;
  Carp->import;
  confess ("Obsolete method called");
}

sub BinariesToIgnore {
  my $self = shift;
  if (exists $self->{binIgnore}) {
    return $self->{binIgnore};
  }
  return [];
}

sub DisallowUnclassifiedSource {
  my $self = shift;
  if (exists $self->{disallow_unclassified_source}) {
    return 1;
  }
  return 0;
}

sub Win32ExtensionsDisabled {
  my $self = shift;
  
  if (exists $self->{disable_win32_extensions}) {
    return 1;
  }
  return 0;
}

sub CategoriseBinaries {
  my $self = shift;
  if (exists $self->{categorise_binaries}) {
    return 1;
  }
  return 0;
}

sub CategoriseExports {
  my $self = shift;
  if (exists $self->{categorise_exports}) {
    return 1;
  }
  return 0;
}

sub RequiredBinaries {
  my $self = shift;
  my $component = lc(shift);
  if (exists $self->{required_binaries}->{$component}) {
    return $self->{required_binaries}->{$component};
  }
  elsif (exists $self->{required_binaries}->{default}) {
    return $self->{required_binaries}->{default};
  }
  return undef;
}

sub TableFormatter {
  my $self = shift;
  require TableFormatter;
  require POSIX;
  # Not 'use' because not many commands draw tables so that would be a waste

  if (!POSIX::isatty('STDOUT')) {
    $self->{table_format} = "text";
    $self->{table_format_args} = "";
  }

  unless (defined $self->{table_formatter}) {
    my $format = $self->{table_format} || "text";
    $self->{table_formatter} = TableFormatter::CreateFormatter($format, $self, $self->{table_format_args});
  }

  return $self->{table_formatter};
}

sub LatestVerFilter {
  my $self = shift;
  unless (exists $self->{latestver_filter}) {
    return undef;
  }
  return $self->{latestver_filter};
}

sub IllegalWorkspaceVolumes {
  my $self = shift;
  if (defined $self->{illegal_workspace_volumes}) {
    return @{$self->{illegal_workspace_volumes}};
  }
  return ();
}

#
# Private
#

sub CheckMappingPath {
  my $self = shift;
  my $operand = shift;

  # Is used to clean up the mapping path.

  $operand =~ s/\//\\/g;

  die "Error: The source_map path $operand must not include a drive letter.\n" if ($operand =~ /^.:/);
  die "Error: The source_map path $operand must be an absolute path without a drive letter.\n" if ($operand !~ /^\\/);
  die "Error: The source_map path $operand must not be a UNC path.\n" if ($operand =~ /^\\\\/);

  #Remove any \\ at the end of the path.
  if($operand =~ /(.*)\\$/){
    $operand = $1;
  }

  return $operand;
}

sub BuildSystemVersion {
  my $self = shift;
  my $verbose = shift;
  
  if (exists $self->{sbs_version}) {
  	print "User set the value of sbs_version to $self->{sbs_version}\n" if($verbose);
    return $self->{sbs_version};
  }
  return "0";
}

sub ExtractMapping {
  my $self = shift;
  my $operand = shift;
  my $epoc32dir = Utils::EpocRoot()."epoc32";

  $operand =~ s/\s+$//;

  if ($operand =~ /^(\S+)\s+(\S+)$/) {
    my $archivePath = $self->CheckMappingPath($1);
    my $localPath = $self->CheckMappingPath($2);

    if($archivePath =~ /^\Q$epoc32dir\E/i){
      die "ERROR: Archive path $epoc32dir... in source mapping is not allowed.\n";
    }
    elsif($localPath =~ /^\Q$epoc32dir\E/i){
      die "ERROR: Local path $epoc32dir... in source mapping is not allowed.\n";
    }

    # Need to check whether the from location is already present in from_mapping array
    if(defined @{$self->{from_mapping}}){
      foreach my $fromMap (@{$self->{from_mapping}}) {
        if(($archivePath =~ /^\W*\Q$fromMap\E\W*$/i) || ($fromMap =~ /^\W*\Q$archivePath\E\W*$/i)){
          die "ERROR: Duplicate <archive_source_directory> $fromMap, <archive_source_directory> $archivePath found in source mappings.\n";
  }
      }
    }

    # Need to check whether the to location is already present in to_mapping array
    if(defined @{$self->{to_mapping}}){
      foreach my $toMap (@{$self->{to_mapping}}) {
        if(($localPath =~ /^\W*\Q$toMap\E\W*$/i) || ($toMap =~ /^\W*\Q$localPath\E\W*$/i)){
          die "ERROR: Duplicate <local_source_directory> $toMap, <local_source_directory> $localPath found in source mappings.\n";
    }
      }
    }

    push @{$self->{from_mapping}}, $archivePath;
    push @{$self->{to_mapping}}, $localPath;
  }
  else{
    die "ERROR: Incorrect usage of source_map keyword in reltools.ini. Expected input is source_map <archive_source_directory> <local_source_directory>\n";
  }
}

sub ReadIni {
  my $self = shift;

  open (INI, $self->{iniFileName}) or die "Unable to open \"$self->{iniFileName}\" for reading: $!\n";

  while (local $_ = <INI>) {
    # Remove line feed, white space and comments.
    chomp;
    s/^\s*$//;
    
    # INC105677 - Warn user if remote_password contains an unescaped #
    if (/remote_password\s+\S*[^\\\s]\#/) {
      warn "Warning: remote_password appears to contain a comment (# characters need to be escaped)\n";
    }
    
    s/(?<!\\)#.*//; # remove comments unless they are immediately preceded by \ (negative lookbehind assertion)
    s/\\#/#/g; # now remove backslashes before # signs
    
    if ($_ eq '') {
      # Nothing left.
      next;
    }

    my $keyWord;
    my $operand;
    if (/^(\w+)\s+(.*)/) {
      $keyWord = $1;
      $operand = $2;
    }
    else {
      # Must be a line with no operand.
      $keyWord = $_;
    }

    unless (defined $keyWord) {
      die "Error: Invalid line in \"$self->{iniFileName}\":\n\t$_\n";
      next;
    }

    if ($keyWord =~ /^diff_tool$/i) {
      Utils::StripWhiteSpace(\$operand);
      $self->{diff_tool} = $operand;
    }
    elsif ($keyWord =~ /^require_internal_versions$/) {
      $self->{require_internal_versions} = 1;
    }
    elsif ($keyWord =~ /^ignore_source_filter_errors$/) {
      $self->{ignore_source_filter_errors} = 1;
    }
    elsif ($keyWord =~ /^html_notes$/) {
      $self->{html_notes} = 1;
    }
    elsif ($keyWord =~ /^temp_dir$/) {
      Utils::StripWhiteSpace(\$operand);
      $operand = File::Spec->catdir($operand);
      $operand =~ s/[\\\/]$//;
      if (!-d $operand  && length $operand) {
        die "Error: Invalid line in \"$self->{iniFileName}\":\n\t$_\n$operand does not exist or is an invalid directory name\n";
      }
      $self->{temp_dir} = $operand;
    }   
    elsif ($keyWord =~ /^remote_site_type$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{remote_site_type} = $operand;
    }
    elsif ($keyWord =~ /^remote_host$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{remote_host} = $operand;
    }
    elsif ($keyWord =~ /^remote_username$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{remote_username} = $operand;
    }
    elsif ($keyWord =~ /^remote_password$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{remote_password} = $operand;
    }
    elsif ($keyWord =~ /^remote_logs_dir$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{remote_logs} = $operand;
    }
    elsif ($keyWord =~ /^pgp_tool$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{pgp_tool} = $operand;
    }
    elsif ($keyWord =~ /^pgp_encryption_key$/) {
      Utils::StripWhiteSpace(\$operand);
      push @{$self->{pgp_encryption_keys}}, $operand;
    }
    elsif ($keyWord =~ /^pgp_config_path$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{pgp_config_path} = $operand;
    }
    elsif ($keyWord =~ /^export_data_file$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{export_data_file} = $operand;
    }
    elsif ($keyWord =~ /^archive_path_file$/) {
      $self->PathData->ProcessLine(\$keyWord, \$operand);
    }
    elsif ($keyWord =~ /^archive_path$/) {
      $self->PathData->ProcessLine(\$keyWord, \$operand);
    }
    elsif ($keyWord =~ /^source_map$/) {
       $self->ExtractMapping($operand);
    }
    elsif ($keyWord =~ /^no_ini_location_warning$/) {
      $self->{warnIniLocation} = 0;
    }
    elsif ($keyWord =~ /^ignore_binary$/) {
      Utils::StripWhiteSpace(\$operand);
      push (@{$self->{binIgnore}}, $operand);
    }
    elsif ($keyWord =~ /^proxy$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{proxy} = $operand;
    }
    elsif ($keyWord =~ /^proxy_username$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{proxy_username} = $operand;
    }
    elsif ($keyWord =~ /^proxy_password$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{proxy_password} = $operand;
    }
    elsif ($keyWord =~ /^pasv_transfer_mode$/) {
      $self->{pasv_transfer_mode} = 1;
    }
    elsif ($keyWord =~ /^ftp_server_supports_resume$/) {
      $self->{ftp_server_supports_resume} = 1;
    }
    elsif ($keyWord =~ /^ftp_timeout$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{ftp_timeout} = $operand;
    }
    elsif ($keyWord =~ /^ftp_reconnect_attempts$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{ftp_reconnect_attempts} = $operand;
    }
    elsif ($keyWord =~ /^max_export_volume_size$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{max_export_volume_size} = $operand;
    }
    elsif ($keyWord =~ /^disallow_unclassified_source$/) {
      $self->{disallow_unclassified_source} = 1;
    }
    elsif ($keyWord =~ /^disable_win32_exten[ts]ions$/) {
      $self->{disable_win32_extensions} = 1;
    }
    elsif ($keyWord =~ /^categori[sz]e_binaries$/) {
      $self->{categorise_binaries} = 1;
    }
    elsif ($keyWord =~ /^categori[sz]e_exports$/) {
      $self->{categorise_exports} = 1;
    }
    elsif ($keyWord =~ /^latestver_filter$/) {
      Utils::StripWhiteSpace(\$operand);
      require Text::Glob;
      $self->{latestver_filter} = Text::Glob::glob_to_regex($operand);;
    }    
    elsif ($keyWord =~ /^required_binaries$/) {
      Utils::StripWhiteSpace(\$operand);
      (my $component, my $required, my $dummy) = split (/\s+/, $operand);
      if ($dummy or not ($component and $required)) {
        die "Error: Invalid line in \"$self->{iniFileName}\":\n\t$_\n";
        next;
      }
      push (@{$self->{required_binaries}->{lc($component)}}, lc($required));
    }
    #Support for target alias file
    elsif ($keyWord =~ /^no_target_alias_warning$/) {
      $self->{mustWarnTargetAliasLocation} = 0;
    }
    elsif ($keyWord =~ /^table_format$/) {
      Utils::StripWhiteSpace(\$operand);
      (my $format, my $args) = $operand =~ m/^(\w+)(.*)$/;
      Utils::StripWhiteSpace(\$args);
      $self->{table_format} = $format;
      $self->{table_format_args} = $args;
    }
    elsif ($keyWord =~ /^illegal_workspace_volumes$/) {
      Utils::StripWhiteSpace(\$operand);
      if ($operand !~ /^[a-z\s,]+$/i) {
        die "Error: Invalid line in \"$self->{iniFileName}\":\n\t$_\n";
      }
      @{$self->{illegal_workspace_volumes}} = split /\s*,\s*/,$operand;
    }
    elsif ($keyWord =~ /^use_distribution_policy_files_first/) {
      $self->{use_distribution_policy_files_first} = 1;
    }
    elsif ($keyWord =~ /^csv_separator$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{csv_separator} = $operand;
    }
    elsif ($keyWord =~ /^sbs_version$/) {
      Utils::StripWhiteSpace(\$operand);
      $self->{sbs_version} = $operand;
    }
    else {
      die "Error: Unknown keyword \"$keyWord\" in \"$self->{iniFileName}\"\n";
    }
  }
  
  close (INI);

  if ($self->{warnIniLocation}) {
    if (defined $$envDir){
       print "Warning: \"$$iniName\" not found in \"$$envDir\", using version found in \"$$binDir\"\n";
    } else {
       print "Warning: Using \"$$iniName\" version found in \"$$binDir\"\n";
    }
    print "         Use the keyword \"no_ini_location_warning\" to disable this warning.\n";
  }
}

sub ReadTargetAliasFile {
  my $self = shift;
  
  if (-e $self->{targetAliasName}) {
    open (ALIAS, $self->{targetAliasName}) or die "Unable to open \"$self->{targetAliasName}\" for reading: $!\n";
    # %allValuesSeenSoFar is a temporary hash of all the values seen so far
    my %allValuesSeenSoFar = ();
    # %aliasMap is the final hash of keys to values with all aliases expanded out
    my %aliasMap = ();
    $self->{alias_map} = {};
    while (local $_ = <ALIAS>) {
      # Remove line feed, white space and comments.
      chomp;
      s/^\s*$//;
      s/(?<!\\)#.*//; # remove comments unless they are immediately preceded by \ (negative lookbehind assertion)
      s/\\#/#/g; # now remove backslashes before # signs
      if ($_ eq '') {
        # Nothing left.
        next;
      }
      my $keyWord;        # The key field
      my @valueList;      # The list of values as read from the line.
      my %seen = ();      # Temporary hash for making values on the line unique
      if (/^\s*(\S+)\s+(.+)/) {
        # Uppercase significant
        $keyWord = uc($1);
        @valueList = split /\s+/, uc($2);
        # Check the key for:
        # A key that has been seen as already as a value i.e. a forward reference - fatal error
        # A key that has been seen as already as a key i.e. a duplicate key - fatal error
        if (exists $allValuesSeenSoFar{$keyWord}) {
          die "Fatal error: Line \"$_\" in $self->{targetAliasName} has forward reference to \"$keyWord\"\n";
        }
        elsif (exists $self->{alias_map}->{$keyWord}) {
          die "Fatal error: Line \"$_\" in $self->{targetAliasName} has duplicate key \"$keyWord\"\n";
        }
        # Check for:
        # Circular references - fatal error
        # Duplicates in the value list - warn and ignore
        foreach my $value (@valueList) {
          if ($value eq $keyWord) {
            die "Fatal error: Line \"$_\" in $self->{targetAliasName} has circular reference in \"$keyWord\"\n"
          }
          elsif (exists $seen{$value}) {
            print "Warning Line \"$_\" in $self->{targetAliasName} has duplicate value entry \"$value\" in key $keyWord\n";
          }
          else {
            # Add to seen map and uniqueList
            $seen{$value} = 1;
            $allValuesSeenSoFar{$value} = 1;
          }
        }
        my @resolvedList = ();  # Resolved aliases
        # Check for the special use of the value '<EMPTY>'
        # If this is present then there must be no other values.
        if (exists $seen{"<EMPTY>"}) {
          if (scalar (keys %seen) > 1) {
            die "Fatal error: Multiple targets in list declared \"<EMPTY>\" for alias \"$keyWord\"\n";
          }
        } else {
          # Now can expand the unique list by resolving aliases against existing keys
          foreach my $uniqueLine (keys %seen) {
            if (exists $self->{alias_map}->{$uniqueLine}) {
              # Expand the list to resolve the aliases
              push(@resolvedList, @{$self->{alias_map}->{$uniqueLine}});
            }
            else {
              # No alias resolution required, just add it
              push(@resolvedList, $uniqueLine);
            }
          }
        }
        # Add the resolved list to the aliasMap
        push( @{$self->{alias_map}->{$keyWord}}, @resolvedList);
      }
      else {
        # A line with no value is illegal.
        # Grab the key word
        if (/^\s*(\S+)/) {
          # Make uppercase as HasTargetPlatforms(), TargetPlatforms()
          # expects uppercase keys
          $keyWord = uc($1);
        } else {
          die "Fatal error: Fatal parser error.\n"
        }
        die "Fatal error: No targets detected for \"$keyWord\"\n"
      }
    unless (defined $keyWord) {
      die "Error: Invalid line in \"$self->{targetAliasName}\":\n\t$_\n";
      next;
    }
  }
  close (ALIAS);
  } else {
    # Failed to find target alias file
    return 0;
  }
  return 1; # Success at reading the file
}

# Support for target alias file
# Returns 1 if target platforms exist for a given alias
# or 0 if no target platforms exist for a given alias
sub HasTargetPlatforms {
  my $self = shift;
  my $alias = shift;
  $alias = uc($alias);
  $self->CheckAliasWarning();
  if (exists $self->{alias_map}) {
    if (exists $self->{alias_map}->{$alias}) {
      return 1;
    }
  }
  return 0;
}

# Support for target alias file
# Returns the arrary of target platforms for a given alias
# or undef if no target platforms for a given alias
sub TargetPlatforms {
  my $self = shift;
  my $alias = shift;
  $self->CheckAliasWarning();
  $alias = uc($alias);
  if (exists $self->{alias_map}) {
    if (exists $self->{alias_map}->{$alias}) {
      return $self->{alias_map}->{$alias};
    }
  }
  # Nothing found so return the callers argument
  return [$alias];
}

sub CheckAliasWarning {
  my $self = shift;
  if ($self->{mustWarnTargetAliasLocation} == 1) {
    print "Warning: \"$self->{targetAliasName}\" not found.\n";
    print "         Use the keyword \"no_target_alias_warning\" to disable this warning.\n";
   }
  $self->{mustWarnTargetAliasLocation} = 0;
}

sub UseDistributionPolicyFilesFirst {
  my $self = shift;
  return !!$self->{use_distribution_policy_files_first};
}

sub CsvSeparator {
  my $self = shift;
  
  if (defined $self->{csv_separator}) {
    return $self->{csv_separator};
  }
  
  return ',';
}

1;

__END__

=head1 NAME

IniData.pm - Provides an interface to the data contained in reltools.ini.

=head1 INTERFACE

=head2 New

Expects to find a file named F<reltools.ini> in the release tools directory, dies if it can't. Parses this file according to the following keywords / value pairs:

 require_internal_versions
 ignore_source_filter_errors
 no_ini_location_warning
 disallow_unclassified_source
 categorise_binaries
 categorise_exports
 html_notes
 archive_path                <archive_name> <archive_path> [<remote_archive_path>]
 diff_tool                   <tool_name>
 export_data_file            <file_name>
 archive_path_file           <file_name>
 source_map                  <archive_source_directory> <local_source_directory>
 remote_site_type            <server_type>
 remote_host                 <host_name>
 remote_username             <user_name>
 remote_password             <pass_word>
 remote_logs_dir             <path>
 pasv_transfer_mode
 ftp_server_supports_resume
 ftp_timeout                 <time_in_seconds>
 ftp_reconnect_attempts      <positive_integer>
 proxy                       <host_name>
 proxy_username              <user_name>
 proxy_password              <pass_word>
 pgp_tool                    <tool_name>
 pgp_encryption_key          <keyid>
 pgp_config_path             <dir_name>
 ignore_binary               <wild_file_name>
 required_binaries           default wins_udeb
 required_binaries           default thumb_urel
 table_format                <table_format module>
 csv_separator               <csv_separator_character>
 sbs_version                 <symbian_build_system>

It assumes # indicates the start of a comment, unless it is preceded by \.

=head2 DiffTool

Returns the name of the differencing tool specified with the C<diff_tool> keyword.

=head2 RequireInternalVersions

Returns true or false depending on whether the C<require_internal_versions> keyword has been specified.

=head2 IgnoreSourceFilterErrors

Returns true or false depending on whether the C<ignore_source_filter_errors> keyword has been specified.

=head2 RemoteSiteType

Returns the type of server hosting the projects remote release archive. Currently this will return either C<'FTP'>, C<'FTP::Proxy'>, C<'NetDrive'>, C<'NetDrive::MultiVolumeExport'> or C<'NetDrive::MultiVolumeImport'>. The default return value is C<'FTP'> if not set.

=head2 RemoteHost

Returns the host address of the project's remote site. If the remote site is an ftp server this will be an ftp address; if it is a network drive then the return value will be a UNC path.

=head2 RemoteUsername

Returns the username for the project's remote site.

=head2 RemotePassword

Returns the password for the project's remote site.

=head2 RemoteLogsDir

Returns the directory on the project's remote site where release notification logs are to be written.

=head2 PasvTransferMode

Returns true or false depending on whether the C<pasv_transfer_mode> keyword has been specified.

=head2 FtpServerSupportsResume

Returns true or false depending on whether the C<ftp_server_supports_resume> keyword has been specified.

=head2 FtpTimeout

Returns the timeout in seconds allowed before dropping the connection to the FTP server

=head2 FtpReconnectAttempts

Returns the number of attempts to reconnect to the FTP site if the connection is dropped

=head2 Proxy

Returns the FTP address of a proxy server used to connect to the project's FTP site.

=head2 ProxyUsername

Returns the username for a proxy server used to connect to the project's FTP site.

=head2 ProxyPassword

Returns the password for a proxy server used to connect to the project's FTP site.

=head2 RemoteSite

Tries to create a RemoteSite object appropriate to the data in the iniData, and return it. Caches the RemoteSite object so that it is only created once.

=head2 MaxExportVolumeSize

Returns the value specified by the keyword C<max_export_volume_size>. If this has not been specified, returns 639 * 1024 * 1024.

=head2 PgpTool

Returns the command line PGP client used to encrypt and decrypt releases.
Currently this will return either C<'PGP'> for NAI Inc. PGP or C<'GPG'> for GNU Privacy Guard. The default return value is C<'PGP'> if not set.

=head2 PgpEncryptionKeys

Returns a reference to an array of PGP key ids (an 8 digit hexadecimal number) used to encrypt all release files before exporting to the remote site. Typically these values will correspond to the local sites project PGP keys so that the user may decrypt their own releases.

=head2 PgpConfigPath

Returns the directory where the users PGP configuration and keyring files are stored.

=head2 ArchivePathFile

Returns the name of the archive path file.

=head2 ExportDataFile

Returns the name of the export data file.

=head2 LocalArchivePath

Expects to be passed a component name. Returns the path to the component's local archive (generally on a LAN share).

=head2 RemoteArchivePath

Expects to be passed a component name. Returns the path to the component's remote archive (may be either on a Network share or an FTP site).

=head2 ListArchiveComponents

Returns a list of component names specified in the archive path file. One of these may be 'default' (if this has been specified). The directories pointed to by this may contain multiple components.

=head2 BinariesToIgnore

Returns a reference to a list of binaries to be ignored when scanning the F<\epoc32> tree. These may contain the C<*> wild character.

=head2 DisallowUnclassifiedSource

Returns false unless the C<disallow_unclassified_source> keyword has been specified.

=head2 Win32ExtensionsDisabled

Returns false unless the C<disable_win32_extensions> keyword has been specified. (Spelling C<disable_win32_extentions> also OK!)

=head2 CategoriseBinaries

Returns false unless the C<categorise_binaries> keyword has been specified.

=head2 CategoriseExports

Returns false unless the C<categorise_exports> keyword has been specified.

=head2 TableFormatter

Returns a TableFormatter object, which can be used to print a table.

=head2 RequiredBinaries

Expects to be passed a component name. Returns the required binaries for that component if any were specified using the C<required_binaries> keyword. If none were, then those specified using C<required_binaries default> are returned. If there are none of those either, then C<undef> is returned - this means that all binaries should be used.

=head2 PathData

Returns a PathData object appropriate to the path configuration data in the ini file. This may be a PathData::ProjectBased or a PathData::ComponentBased object.

=head2 FromMapping

Returns an array of <archive_source_directory> mappings. If there are no mappings defined an undefined value is returned.

=head2 ToMapping

Returns an array of <local_source_directory> mappings. If there are no mappings defined an undefined value is returned.

=head2 HasMappings

Returns false if no mappings are defined. Otherwise returns true.

=head2 PerformMapOnFileName

Reads a filename and takes all mappings defined into consideration with <archive_source_directory> being mapped to <local_source_directory>. Returns the new filename, with the mappings processed.

=head2 PerformReverseMapOnFileName

Reads a filename and takes all mappings defined into consideration with <local_source_directory> being mapped to <archive_source_directory>. Returns the new filename, with the mappings processed.

=head2 CheckMappingPath

Expects a mapping path which is checked. Any problems with the path are reported and the program exits. Otherwise returns the checked mapping path.

=head2 ExtractMapping

Is used to extract and store the local and archive mappings directories as defined. If an usage error is encountered, an error message is displayed and the program exits.

=head2 CheckFileNameForMappingClash

Is used to check if any of the mappings defined clash with the filename passed. If there is a clash an error message is shown and the program exits.

=head2 HasTargetPlatforms

Returns true if there is are any target platforms for a given alias. False otherwise.

=head2 TargetPlatforms

Returns a reference to a list containing either the platforms for a given alias or the alias itself (i.e. not an alias but a platform name).

=head2 CsvSeparator

Returns the separator to be used for CSV files, which by default is a comma ','.  Depending on the locale, the separator may be different.  The user can specify the separator required by using the C<csv_separator> keyword.


=head1 KNOWN BUGS

None.

=head1 COPYRIGHT

 Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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

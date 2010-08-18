# ============================================================================
#  Name        : s60ibymacros.pm
#  Part of     : build_RnD
#  Description : S60 specific IBY file macro handling
#  Version     : %version: 1 %
#
#  Copyright © 2006 Nokia.  All rights reserved.
#  This material, including documentation and any related computer
#  programs, is protected by copyright controlled by Nokia.  All
#  rights are reserved.  Copying, including reproducing, storing,
#  adapting or translating, any or all of this material requires the
#  prior written consent of Nokia.  This material also contains
#  confidential information which may not be disclosed to others
#  without the prior written consent of Nokia.
# ============================================================================
#
# 07.08.2006 Juha Ristimäki
# Initial version.
#

package s60ibymacros;

BEGIN
  {
  use Exporter ();
  our ( $VERSION, @ISA, @EXPORT );
  # set the version for version checking
  $VERSION     = 1.00;

  @ISA         = qw( Exporter );
  @EXPORT      = qw( &s60ibymacros_info &DoS60IbyModifications );
  }

my %s60ibymacros_infostruct =
  (
  name => "s60ibymacros",
  invocation => "InvocationPoint1",
  single => "s60ibymacros::DoS60IbyModifications"
  );

my @newobydata;

sub s60ibymacros_info
  {
  return \%s60ibymacros_infostruct;
  }

sub DoS60IbyModifications
  {
  my $obydata = shift;

  undef @newobydata;
  foreach $line (@{$obydata})
    {
    if ($line =~ /^\s*REM/i)
      {
      # Ignore REM statements, to avoid processing "REM __SCALABLE_IMAGE( ... )"
      push @newobydata, $line;
      }
    elsif( ! ( HandleIconMacros($line) || HandleCenrepMacros($line) ) )
      {
      push @newobydata, $line;
      }
    }
  @{$obydata} = @newobydata;
  }

sub HandleCenrepMacros
  {
  my $line = shift;
  if ( $line =~ m/^.*__CENREP_TXT_FILES\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/i )
  # __CENREP_TXT_FILES(dataz_, source dir, target dir)
    {
    my $sourcepath="$1\\$2";
    my $targetpath=$3;
    my $s60extras_export_list_filename = "$sourcepath"."\\s60extras_export_list.txt";

    open(DH, $s60extras_export_list_filename);
    my @dlist = <DH>;
    chop @dlist;
    close(DH);

    my $cenreptxtfile;
    foreach $cenreptxtfile (@dlist)
      {
      if ($cenreptxtfile =~ /^\S+\.txt/)
        {
        push @newobydata, "data=$sourcepath\\$cenreptxtfile $targetpath\\$cenreptxtfile\n";
        }
      }
    return 1;
    }
  }

sub HandleIconMacros
  {
  my $line = shift;
  if ( $line =~ m/^.*__SCALABLE_IMAGE\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/i )
  # __SCALABLE_IMAGE(emulator directory, file rom dir, dataz_, resource rom dir,
  #                  filename, resource filename)
    {
      
    my $sourcepath="$1\\$2";
    my $targetpath=$3;
    my $filename=$4;

    if( -e "$sourcepath\\$filename.mbm" )
      {
      push @newobydata, "AUTO-BITMAP=$sourcepath\\$filename.mbm $targetpath\\$filename.mbm\n";
      }
    if( -e "$sourcepath\\$filename.mif" )
      {
      push @newobydata, "data=$sourcepath\\$filename.mif $targetpath\\$filename.mif\n";
      }
    elsif( ! -e "$sourcepath\\$filename.mbm ")
      {
      print STDERR "* Invalid image file name: $sourcepath\\$filename.mbm or .mif\n";
      }
    return 1;
    }
  }

1;  # Return a true value from the file
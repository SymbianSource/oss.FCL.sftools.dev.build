# RemoteSite::FTP.pm
#
#Copyright (c) 2000-2006, The Perl Foundation. All rights reserved.
#This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
#

package RemoteSite::FTP::Experimental;

use strict;

use RemoteSite::FTP;
use vars qw(@ISA);
@ISA=("RemoteSite::FTP");

sub DirList {
  my $self = shift;
  my $remoteDir = shift;

  print "Listing FTP directory $remoteDir\n" if ($self->{verbose});

  my $dirlist_retries = 3;
  
  $remoteDir =~ s{\\}{\/}g;   #convert back slashes to forward slashes
  
  my $retry;
  for ($retry = 0; $retry < $dirlist_retries; $retry++) {

    unless ($self->Connected()) {
      $self->Connect();
    }

    # The Net::FTP module that we're using here has two options for listing the contents 
    # of a directory. They are the 'ls' and 'dir' calls.
    # The 'ls' call is great, and just returns a list of the items. But, irritatingly, it
    # misses out directories: the returned list just contains names of *files*.
    # dir is better, in some ways, as it lists directories too, but its output format
    # varies from one FTP site to the next. So we have to stick with ls.
    print "About to call dir(\"$remoteDir\")\n" if ($self->{verbose});
    my %hash = $self->dir($remoteDir);
    my @items = keys %hash;
    @items = grep { $_ ne "." && $_ ne ".." } @items;
    @items = map { "$remoteDir/$_" } @items; # prepend the path as that's the output format
      # that is expected of this function
    return \@items;
  }
  die "Error: have tried to list \"$remoteDir\" $retry times with no success - giving up\n";
}

# Code from Net::FTP::Common v 4.0a
sub dir {       
  my ($self, $directory) = @_;

  my $ftp = $self->{ftp};

  my $dir = $ftp->dir($directory);
  if (!defined($dir)) {
    return ();
  } else
  {
    my %HoH;

    # Comments were made on this code in this thread:
    # http://perlmonks.org/index.pl?node_id=287552

    foreach (@{$dir})
        {
	      $_ = m#([a-z-]*)\s*([0-9]*)\s*([0-9a-zA-Z]*)\s*([0-9a-zA-Z]*)\s*([0-9]*)\s*([A-Za-z]*)\s*([0-9]*)\s*([0-9A-Za-z:]*)\s*([\w*\W*\s*\S*]*)#;

        my $perm = $1;
        my $inode = $2;
        my $owner = $3;
        my $group = $4;
        my $size = $5;
        my $month = $6;
        my $day = $7;
        my $yearOrTime = $8;
        my $name = $9;
        my $linkTarget;

        if ( $' =~ m#\s*->\s*([A-Za-z0-9.-/]*)# )       # it's a symlink
                { $linkTarget = $1; }

        $HoH{$name}{perm} = $perm;
        $HoH{$name}{inode} = $inode;
        $HoH{$name}{owner} = $owner;
        $HoH{$name}{group} = $group;
        $HoH{$name}{size} = $size;
        $HoH{$name}{month} = $month;
        $HoH{$name}{day} = $day;
        $HoH{$name}{yearOrTime} =  $yearOrTime;
        $HoH{$name}{linkTarget} = $linkTarget;

        }
  return(%HoH);
  }
}


1;

=head1 NAME

RemoteSite::FTP::Experimental.pm - Access a remote FTP site.

=head1 DESCRIPTION

C<RemoteSite::FTP::Experimental> is inherited from the abstract base class C<RemoteSite>, implementing the abstract methods required for transfer of files to and from a remote site when the remote site is an FTP server.

This class differs from C<RemoteSite::FTP> only in using a different mechanism for listing the contents of directories on FTP sites.

=head1 KNOWN BUGS

None

=head1 COPYRIGHT

Copyright (c) 2000-2006, The Perl Foundation. All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

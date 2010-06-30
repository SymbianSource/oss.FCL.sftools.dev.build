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
# Description:
# RemoteSite::FTP::Proxy::Experimental.pm
#

package RemoteSite::FTP::Proxy::Experimental;

use strict;

use RemoteSite::FTP::Experimental;
use RemoteSite::FTP::Proxy;
use vars qw(@ISA);
@ISA=("RemoteSite::FTP::Experimental", "RemoteSite::FTP::Proxy");

sub Connect {
	my $self = shift;
	$self->RemoteSite::FTP::Proxy::Connect();
}

sub DirList {
	my $self = shift;
	$self->RemoteSite::FTP::Experimental::DirList();
}

1;

=head1 NAME

RemoteSite::FTP::Experimental::Proxy.pm - Access a remote FTP site.

=head1 DESCRIPTION

This class differs from C<RemoteSite::FTP::Proxy> only in using a different mechanism for listing the contents of directories on FTP sites.

=head1 KNOWN BUGS

None

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

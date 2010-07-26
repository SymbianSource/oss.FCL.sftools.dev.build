# Copyright (c) 1995-98 Gurusamy Sarathy.  All rights reserved.
#
# Copyright (c) 1998 Raphael Manfredi.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MLDBM::Serializer::FreezeThaw;
BEGIN { @MLDBM::Serializer::FreezeThaw::ISA = qw(MLDBM::Serializer) }

use FreezeThaw;

sub serialize {
    return FreezeThaw::freeze($_[1]);
}

sub deserialize {
    my ($obj) = FreezeThaw::thaw($_[1]);
    return $obj;
}

1;
__END__

=head1 COPYRIGHT

Gurusamy Sarathy <F<gsar@umich.edu>>.

Support for multiple serializing packages by
Raphael Manfredi <F<Raphael_Manfredi@grenoble.hp.com>>.

Copyright (c) 1995-98 Gurusamy Sarathy.  All rights reserved.

Copyright (c) 1998 Raphael Manfredi.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

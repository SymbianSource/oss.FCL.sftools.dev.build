# Copyright (c) 1995-98 Gurusamy Sarathy.  All rights reserved.
#
# Copyright (c) 1998 Raphael Manfredi.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package MLDBM::Serializer::Storable;
BEGIN { @MLDBM::Serializer::Storable::ISA = qw(MLDBM::Serializer) }

use Storable;

sub new {
    my $self = shift->SUPER::new();
    $self->DumpMeth(shift);
    # Storable doesn't honor other attributes
    $self;
}

#
# Serialize a reference to supplied value
#
sub serialize {
    my $self = shift;
    my $dumpmeth = $self->{'_dumpsub_'};
    &$dumpmeth(\$_[0]);
}

#
# Deserialize and de-reference
#
sub deserialize {
    my $obj = Storable::thaw($_[1]);		# Does not care whether portable
    defined($obj) ? $$obj : undef;
}

#
# Change dump method when portability is requested
#
sub DumpMeth {
    my $self = shift;
    $self->{'_dumpsub_'} = 
      ($_[0] && $_[0] eq 'portable' ? \&Storable::nfreeze : \&Storable::freeze);
    $self->_attrib('dumpmeth', @_);
}

1;
__END__

=head1 AUTHORS

Gurusamy Sarathy <F<gsar@umich.edu>>.

Support for multiple serializing packages by
Raphael Manfredi <F<Raphael_Manfredi@grenoble.hp.com>>.

Copyright (c) 1995-98 Gurusamy Sarathy.  All rights reserved.

Copyright (c) 1998 Raphael Manfredi.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

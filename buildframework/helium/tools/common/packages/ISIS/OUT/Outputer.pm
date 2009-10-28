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
#!/usr/bin/perl -w
#--------------------------------------------------------------------------------------------------
# Name   : Outputer.pm
# Use    : Contains an instanciable package to write complex html files.

#
# Synergy :
#
# Version History :
# v1.0.3 (06/04/2006)
#  - Reworte the way user defined CSS files are handled to make sure they are the last ones
#    included in the document body to allow overwriting of certain values.
#
# v1.0.2 (05/04/2006)
#  - Changed storage for CSS and JS files to arrays to keep inputed order.
#
# v1.0.1 (07/02/2006)
#  - Updated 'Outputer' package to use HTTP Server.
#
# v1.0.0 (12/11/2005)
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------
#
#   OUT::Outputer package.
#
#--------------------------------------------------------------------------------------------------

package OUT::Outputer;

use strict;
use warnings;
use ISIS::HttpServer;
use ISIS::XMLManip;
use ISIS::OUT::Debug;

use constant ISIS_VERSION     => 'v1.0.3';
use constant ISIS_LAST_UPDATE => '05/04/2006';

#--------------------------------------------------------------------------------------------------
# Constructor.
#--------------------------------------------------------------------------------------------------
sub new
{
  warn "new OUT::Outputer( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $ostream, $config, $interface_root, %vars) = (shift, shift, shift, shift);
  my (@stylesheets, @javascripts, @user_stylesheets, @user_javascripts);
  
  if(not defined $interface_root) { $interface_root = ''; }
  else { $interface_root .= '/' if($interface_root !~ /.+\/$/); }
  
  $vars{'OUT::Outputer::Ofile'}        = $ostream;
  $vars{'OUT::Outputer::Indent'}       = '';
  $vars{'OUT::Outputer::Id'}           = 0;
  $vars{'OUT::Outputer::Interface'}    = $interface_root;
  $vars{'OUT::Outputer::CSSFiles'}     = \@stylesheets;
  $vars{'OUT::Outputer::JSFiles'}      = \@javascripts;
  $vars{'OUT::Outputer::UserCSSFiles'} = \@user_stylesheets;
  $vars{'OUT::Outputer::UserJSFiles'}  = \@user_javascripts;

	if ($interface_root =~ /^http:\/\//)
	{
		my $temp = $ENV{'TEMP'} || $ENV{'TMP'} || '.';
		HttpServer::GetFile("$interface_root$config", "$temp/$config"); # or die "Unable to retrieve configuration file $config";
		$vars{_cfg} = &XMLManip::ParseXMLFile("$temp/$config");
	}
	else
	{
		$vars{_cfg} = &XMLManip::ParseXMLFile($interface_root.$config);
	}
  
  foreach (@{$vars{_cfg}->Childs()})
  {
    if(defined @{$vars{_cfg}->Childs()})
    { 
      $vars{'_cfg_'.$_->Type()} = $_->Childs();
    }
  }

  bless \%vars, $self;
}

#--------------------------------------------------------------------------------------------------
# Factory
#--------------------------------------------------------------------------------------------------
sub Create
{
  warn "OUT::Outputer::Create( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $type) = (shift, 'OUT::'.shift);
  
  eval "require ISIS::$type";
  if($@){ warn $@; return undef; }
  return $type->new(@_, $self);
}

#--------------------------------------------------------------------------------------------------
# Print
#--------------------------------------------------------------------------------------------------
sub Print
{
  warn "OUT::Outputer::Print( ".$_[0]." )\n" if(DBG::OUTPUTER);
  my $self   = shift;
  my $indent = $self->{'OUT::Outputer::Indent'};
  my $out    = $self->{'OUT::Outputer::Ofile'};

  my @lines = map{ $indent.$_."\n" } split('\n', join('', @_));

  $out->print(join('', @lines)) if @_;
}

#--------------------------------------------------------------------------------------------------
# RequireCSSFile
#--------------------------------------------------------------------------------------------------
sub RequireCSSFile
{
  warn "OUT::Outputer::RequireCSSFile( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $filename) = (shift, shift);
  
  foreach my $css (@{$self->{'OUT::Outputer::CSSFiles'}})
  { return if($css eq $filename); }
  
  push @{$self->{'OUT::Outputer::CSSFiles'}}, $filename;
}

#--------------------------------------------------------------------------------------------------
# RequireJavaScript
#--------------------------------------------------------------------------------------------------
sub RequireJSFile
{
  warn "OUT::Outputer::RequireJSFile( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $filename) = (shift, shift);
  
  foreach my $js (@{$self->{'OUT::Outputer::JSFiles'}})
  { return if($js eq $filename); }
  
  push @{$self->{'OUT::Outputer::JSFiles'}}, $filename;
}

#--------------------------------------------------------------------------------------------------
# RequireCSSFile
#--------------------------------------------------------------------------------------------------
sub UserRequireCSSFile
{
  warn "OUT::Outputer::UserRequireCSSFile( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $filename) = (shift, shift);

  foreach my $css (@{$self->{'OUT::Outputer::UserCSSFiles'}})
  { return if($css eq $filename); }

  push @{$self->{'OUT::Outputer::UserCSSFiles'}}, $filename;
}

#--------------------------------------------------------------------------------------------------
# RequireJavaScript
#--------------------------------------------------------------------------------------------------
sub UserRequireJSFile
{
  warn "OUT::Outputer::UserRequireJSFile( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $filename) = (shift, shift);
  
  foreach my $js (@{$self->{'OUT::Outputer::UserJSFiles'}})
  { return if($js eq $filename); }
  
  push @{$self->{'OUT::Outputer::UserJSFiles'}}, $filename;
}

#--------------------------------------------------------------------------------------------------
# Get icon based on keyword.
#--------------------------------------------------------------------------------------------------
sub GetAssociatedImage
{
  warn "OUT::Outputer::GetAssociatedImage( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $type, $res) = (shift, shift);
  
  foreach (@{$self->{_cfg_icons}})
  {
    my $pattern = $_->Attribute('type');
    if($type =~ /^$pattern$/)
    {
      return $self->Create('Image', $_->Attribute('img'),
                                    $_->Attribute('width'),
                                    $_->Attribute('height'),
                          );
    }
  }
  
  return undef;
}

#--------------------------------------------------------------------------------------------------
# Get class based on keyword.
#--------------------------------------------------------------------------------------------------
sub GetAssociatedClass
{
  warn "OUT::Outputer::GetAssociatedClass( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  my ($self, $type, $res) = (shift, shift);
  
  $res = "undefined_type_".join('_', split(' ', $type));
  
  foreach (@{$self->{_cfg_icons}})
  {
    my $pattern = $_->Attribute('type');
    if($type =~ /^$pattern$/)
    { return $_->Attribute('class'); }
  }
  
  return $res;
}

#--------------------------------------------------------------------------------------------------
# Accessor.
#--------------------------------------------------------------------------------------------------
sub AUTOLOAD
{ 
  my ($self, $method) = (shift, our $AUTOLOAD);
  warn "$method( ".join(', ', @_)." )\n" if(DBG::OUTPUTER);
  return if($method =~ /::DESTROY$/ or not exists $self->{$method});
 
  $self->{$method} = shift if @_;
  return $self->{$method}; 
}

#--------------------------------------------------------------------------------------------------
# Accessor subroutine to be called by OUT packages by their AUTOLOAD overload.
# Takes the normal method autoload name, ie : 'OUT::Node::Text', and strips out all package
# reference, adds an underscore and lowercases the method name, ie '_text'.
#--------------------------------------------------------------------------------------------------
sub _Accessor
{
  my ($self, $object, $method) = (shift, shift, shift);
  return if($method =~ /::DESTROY$/);
  
  $method =~ s/^.*:://;
  $method = lc($method);
  return if not exists $object->{$method};
  
  $object->{$method} = shift if @_;
  return $object->{$method};
}

1;

#--------------------------------------------------------------------------------------------------
# Documentation.
#--------------------------------------------------------------------------------------------------

=pod

=head1 NAME

OUT::Outputer - OUT object factory and printer for complex html files.

=head1 SYNOPSIS

  use ISIS::HTMLManip;

  open($ostream, '>'.$htmlfile) or return ERR::FILE_CREATION_FAILED;
  my $outputer = new HTMLManip($ostream, 'configuration.xml', 'isis_interface');
  
  my $object = $outputer->Create('ObjectType', $arg1, $arg2, ...);

=head1 DESCRIPTION

The Outputer package provides the mechanics necessary to have all objects of the
OUT module coexist and communicate. From a user's point of view, it acts as an 
OUT object factory. The 'Create' function calls the object type constructor and
passes itself as the last argument of the constructor, allowing created objects
to directly interact with the outputer they will be using.

=head2 Outputer ( OSTREAM, CONFIGURATION, INTERFACE ) :

Returns a newly constructed L<OUT::Outputer> instance that will printout to the passed
output stream. The configuration file is used for generic values such as icons and 
colors. The interface determines the root directory from with all the HTML style information
will be taken. For a simpler use, this constructor should not be called directly, but
the user should load the L<ISIS::HTMLManip> module that provides a wrapper constructor.

The Outputer contains at least one hidden hash key '_cfg' that accesses the root node
of the parsed XML configuration file using the L<ISIS::XMLManip> module. All child nodes
of the root node of the XML configuration file will be used as keys '_cfg_.name'for access
to an array containing itself all their child nodes for easier access :

Such an XML configuration file :

  <htmloutput>
    <icons>
      <icon type="error"   class=".msg_error"   img="img/icons/error.gif"   width="16" height="16"/>
      <icon type="warning" class=".msg_warning" img="img/icons/warning.gif" width="16" height="16"/>
      <icon type="good"    class=".msg_good"    img="img/icons/good.gif"    width="16" height="16"/>
      <icon type=".*"      class=".msg_default" img="img/icons/default.png" width="20" height="16"/>
    </icons>
  </htmloutput>

Will result in this hash table :

  $vars{_cfg} => htmloutputNode;
  $vasr{_cfg_icons} => @{ iconNode, iconNode, iconNode, iconNode };

For more information on how to access data from that root node, see the L<ISIS::XMLManip>
documentaion.

=head2 Create ( OBJECTTYPE, [ARG1, [ARG2, ...]] ) :

Returns an OUT object created by a call to the object type constructor. Arguments that
need to be passed to the constructor can be passed via this subroutine. The necessary
OUT:: submodule for creating the object will be loaded. If the module is not found, or
the constructor fails, undef will be returned. Note that the objecttype should not contain
the 'OUT::' prefix, as the only place the factory will look for the module is in the OUT
subdirectory.

=head2 RequireCSSFile( PATH ) :

Should be called by an OUT object's constructor. This registers a CSS file necessary for
the correct displaying of the caller object's class. The same file can be specified several
times without harm.

=head2 RequireJSFile( PATH ) :

Should be called by an OUT object's constructor. This registers a JavaScript file necessary
for the correct displaying of the caller object's class. The same file can be specified
several times without harm.

=head2 GetAssociatedImage( FILETYPE ) :

Returns the correct image based on a file type. Icons should be specified in the
configuration XML file used by the outputer, for more information on the XML configuration
file, see L<CONFIGURATION FILE>.

=head2 GetAssociatedClass( FILETYPE ) :

Returns the correct class based on a file type. Icons should be specified in the configuration
XML file used by the outputer, for more information on the XML configuration file, see
L<CONFIGURATION FILE>.

=head2 Print( TEXT ) :

Prints the text to the output stream associated to the outputer. There is no need to take
care of the indentation prior to a call to print since it will automatically be formatted.

=head2 Indent(  ) :

Sets or returns the current indent used when printing to the output stream to respect HTML
node indentations. This value can be freely changed by the user.

=head2 Interface(  ) :

Sets or returns the interface root to be used when looking for javascript, css and image files.

=head2 Id(  ) :

Sets or returns the current global id used when printing out HTML nodes. This Id is used to
uniquely identify certain HTML nodes throughout the HTML document allowing javascripts to
access these nodes using the javascript 'GetElementById' function. Users should remember to
increment this value as soon as they do not require it anymore.

=head2 _Accessor(  ) :

This subroutine is a simple AUTOLOAD accessor that can be called directly by OUT objects. OUT
object authors can easily define an accessor with the following syntax.

  sub new
  {
    bless { # other hash elements ...
            _outputer => pop,
          }, shift;
  }

  sub AUTOLOAD
  {
    my ($self, $method) = (shift, our $AUTOLOAD);
    return $self->{_outputer}->_Accessor($self, $method, @_);
  }

This allows to avoid having long hash strings as keys like the classic AUTOLOAD mechanism. For
example, if the OUT object has an 'icon' object in its hash :

  sub new
  {
    bless { icon      => undef, # initialization
            _outputer => pop,
          }, shift;
  }

And having the same AUTOLOAD definition as above, you can just call:

  my $obj = $outputer->Create('obj_type'); # and other eventual args.
  $obj->Icon()         # will return $obj->{icon}.
  $obj->Icon($my_icon) # will set $obj->{icon} = $my_icon.

=head1 AUTHOR



=cut

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------

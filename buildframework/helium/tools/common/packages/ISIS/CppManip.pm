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
# Name : CppManip.pm
# Use  : Generate HTML versions of C/C++ source code.
#
# Synergy :
# Perl %name    : % (%full_filespec :  %)
# %derived_by   : %
# %date_created : %
#
# History :
# v1.0.1 (09/02/2006)
#  - Updated regular expression generations to take place in BEGIN block.
#
# v1.0.0 (06/02/2006)
#  - Fist version of the script.
#--------------------------------------------------------------------------------------------------

package CPPManip;

use strict;
use warnings;

use constant ISIS_VERSION     => '1.0.1';
use constant ISIS_LAST_UPDATE => '09/02/2006';

#--------------------------------------------------------------------------------------------------
# Symbols and Keywords for C++.
#--------------------------------------------------------------------------------------------------
my (@__keywords, @__preprocessors, @__symbols);
my ($symbols, $string, $character, @keywords, @preprocessors, $elememts);

BEGIN
{
	@__keywords = 
	(
	  'class', 'auto', 'break', 'bool', 'case', 'char', 'const', 'continue', 'catch', 'const_cast',
	  'default', 'delete', 'do', 'double', 'dynamic_cast', 'else', 'enum', 'explicit', 'export', 'extern',
	  'false', 'float', 'for', 'friend', 'goto', 'if', 'inline', 'int', 'long', 'mutable', 'new', 'namespace',
	  'operator', 'private', 'protected', 'public', 'register', 'reinterpret_cast', 'return', 'short',
	  'signed', 'sizeof', 'static', 'static_cast', 'struct', 'switch', 'template', 'this', 'throw', 'true',
	  'try', 'typedef', 'typeid', 'typename', 'union', 'unsigned', 'using', 'virtual', 'void', 'volatile',
	  'wchar_t', 'while', '__asm', '__based', '__cdecl', '__declspec', '__except', '__far', '__fastcall',
	  '__finally', '__fortran', '__huge', '__inline', '__int16', '__int32', '__int64', '__int8', '__interrupt',
	  '__leave', '__loadds', '__multiple_inheritance', '__near', '__pascal', '__saveregs', '__segment',
	  '__segname', '__self', '__single_inheritance', '__stdcall', '__try', '__uuidof', '__virtual_inheritance',
	);
	
	@__preprocessors =
	( 
	  'defined', '#define', '#error', '#include', '#elif', '#ifndef', '#ifdef',
	  '#if', '#line', '#else', '#pragma', '#endif', '#undef',
	);
	
	@__symbols =
	( 
	  '\*', '\/', '\+', '\-', '\&', '=', '\!', '\?', '\:', '\;', '\,', '\~',
	  '\(', '\)', '\<', '\>', '\[', '\]', '\{', '\}', '\s+'
	);
	
	$symbols       = '(['.join('', @__symbols).']+)';
	$string        = '(\"[^\"]*\")';
	$character     = "(\'[^\']*\')";
	@keywords      = map { '[^\w_-]+('.$_.')[^\w_-]+' } @__keywords;
	@preprocessors = map { '('.$_.')' } @__preprocessors;
	$elements      = join('|', $string, $character, $symbols, @preprocessors, @keywords);
}

#--------------------------------------------------------------------------------------------------
# Main subroutine.
#--------------------------------------------------------------------------------------------------
sub new
{
	my ($class, $input, $ostream, $css) = (shift, shift, shift);
	
	bless { __input   => $input, 
		      __ostream => $ostream,
					__classes => $css || {},
				}, $class;
}

sub SetClass
{
	my ($self, $type, $class) = (shift, shift, shift);
	
	$self->{__classes}->{$type} = $class;
}

sub Format
{	
	my ($self, $code, $cmt, $inCmt) = (shift, undef, undef, 0);
	my $OUT = $self->{__ostream};
	
	open(IN, $self->{__input}) or die "Unable to open file ".$self->{__input}." : $!\n";
	
	print $OUT "<PRE class=\"", $self->{__classes}->{pre} || 'code_sample', "\">\n";

	while(my $line = <IN>)
	{
		if($line =~ /^\s*$/)
		{
			print $OUT $line;
		}
		elsif($inCmt)
		{
			if(($cmt, $code) = ($line =~ /^(.*\*\/)(.*?)\n$/))
			{
				$inCmt = 0;
				print $OUT $self->__format_comment($cmt),
				           $self->__format_code($code),
				           "\n";
			}
			else
			{
				chomp($line);
				print $OUT $self->__format_comment($line),
				           "\n";
			}
		}
		elsif(($code, $cmt) = ($line =~ /^(.*?)(\/\/.*)\n$/))
		{
			print $OUT $self->__format_code($code),
			           $self->__format_comment($cmt),
			           "\n";
		}
		elsif($line =~ s/(\/\*.*\*\/)/<span class=\"code_cmt\">$1<\/span>/g)
		{
			print $OUT $line;
		}
		elsif(($code, $cmt) = ($line =~ /^(.*?)(\/\*.*)\n$/))
		{
			$inCmt = 1;
			print $OUT $self->__format_code($code),
			           $self->__format_comment($cmt),
			           "\n";
		}
		else
		{
			print $OUT $self->__format_code($line);
		}
	}
	
	print $OUT "</PRE>\n";
	
	close(IN);
}

#--------------------------------------------------------------------------------------------------
# Formatting subroutines.
#--------------------------------------------------------------------------------------------------
sub __format_code
{
	my ($self, $code, $found) = (shift, shift, 0);
	my @__code = grep{ $_ } split($elements, $code);
	
	foreach (@__code)
	{
		next if(/^\s*$/);
		next if(s/^(\".*\")$/"<span class=\"".($self->{__classes}->{str} || 'code_str')."\">$1<\/span>"/e);
		next if(s/^(\'.*\')$/"<span class=\"".($self->{__classes}->{chr} || 'code_chr')."\">$1<\/span>"/e);
		next if(s/($symbols)/"<span class=\"".($self->{__classes}->{smb} || 'code_smb')."\">$1<\/span>"/e);
		
		$found = 0;
		
		foreach my $kwd (@__keywords)
		{ if(s/^($kwd)$/"<span class=\"".($self->{__classes}->{kwd} || 'code_kwd')."\">$1<\/span>"/e)
			{ $found = 1; last; }
		}

		next if($found);

		foreach my $kwd (@__preprocessors)
		{ if(s/^($kwd)$/"<span class=\"".($self->{__classes}->{pp} || 'code_pp')."\">$1<\/span>"/e)
			{ $found = 1; last; }
		}
	}
	
	return join('', @__code);
}

sub __format_comment
{
	my ($self, $cmt) = (shift, shift);

	$cmt =~ s/(.*)/"<span class=\"".($self->{__classes}->{cmt} || 'code_cmt')."\">$1<\/span>"/e;
	return $cmt;
}

1;

#--------------------------------------------------------------------------------------------------
# End of file.
#--------------------------------------------------------------------------------------------------

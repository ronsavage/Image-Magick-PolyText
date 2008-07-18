package Image::Magick::PolyText::FreeType;
{
use base qw( Image::Magick::PolyText );
use strict;
use version; our $VERSION = qv('1.0.0');
use warnings;

use File::Temp;
use Font::FreeType;
use Image::Magick;
use POSIX qw( ceil );

# ------------------------------------------------
# Attributes.

my %debug        : ATTR(init_arg => 'debug',        default => 0);
my %fill         : ATTR(init_arg => 'fill',         default => 'Red');
my %image        : ATTR(init_arg => 'image');
my %pointsize    : ATTR(init_arg => 'pointsize',    default => 16);
my %rotate       : ATTR(init_arg => 'rotate',       default => 1);
my %slide        : ATTR(init_arg => 'slide',        default => 0);
my %stroke       : ATTR(init_arg => 'stroke',       default => 'Red');
my %strokewidth  : ATTR(init_arg => 'strokewidth',  default => 1);
my %text         : ATTR(init_arg => 'text');
my %x            : ATTR(init_arg => 'x');
my %y            : ATTR(init_arg => 'y');

# ------------------------------------------------
# Constants.

Readonly::Scalar my $pi => 3.14159265;

# ------------------------------------------------
# Methods.

sub annotate
{
	my $self = shift @_;
	my $id   = ident $self;
	my $font = $image{$id} -> Get('font');

	print "Font: $font. \n";

	my $face = Font::FreeType -> new() ->face($font, load_flags => FT_LOAD_NO_HINTING);

	$face -> set_char_size($pointsize{$id}, 0, 72, 72);

	if ($debug{$id})
	{
		$self -> dump();
	}

	my $bitmap;
	my $i;
	my $result;
	my $rotation;
	my @text = split //, $text{$id};
	my @value;
	my $x = $x{$id}[0];
	my $y;

	if ($slide{$id})
	{
		my $b    = Math::Bezier -> new(map{($x{$id}[$_], $y{$id}[$_])} 0 .. $#{$x{$id} });
		($x, $y) = $b -> point($slide{$id});
	}

	for ($i = 0; $i <= $#text; $i++)
	{
		@value    = Math::Interpolate::robust_interpolate($x, $x{$id}, $y{$id});
		$rotation = $rotate{$id} ? 180 * $value[1] / $pi : 0; # Convert radians to degrees.
		$y        = $value[0];
		$result   = $image{$id} -> Composite
		(
		compose => 'Over',
		image   => $self -> glyph2svg2bitmap($face, $text[$i], $rotation),
		x       => $x,
		'y'     => $y, # y eq tr, so syntax highlighting stuffed without ''.
		);

		die $result if $result;

		$x += $pointsize{$id};
	}

}	# End of annotate.

# ------------------------------------------------

sub glyph2svg2bitmap
{
	my $self     = shift @_;
	my $face     = shift @_;
	my $char     = shift @_;
	my $rotation = shift @_;
	my $glyph    = $face -> glyph_from_char_code(ord $char);

	if (! (defined $glyph && $glyph -> has_outline() ) )
	{
		$glyph = $face -> glyph_from_char_code('?');
	}

	my ($xmin, $ymin, $xmax, $ymax) = $glyph -> outline_bbox();
	$xmax    = ceil $xmax;
	$ymax    = ceil $ymax;
	my $path = $glyph -> svg_path();
	my $fh   = File::Temp -> new();

	print $fh 
	"<?xml version='1.0' encoding='UTF-8'?>\n" .
    "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"\n" .
    "    \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n\n" .
    "<svg xmlns='http://www.w3.org/2000/svg' version='1.0'\n" .
    "     width='$xmax' height='$ymax'>\n\n" .
    # Transformation to flip it upside down and move it back down into
    # the viewport.
    " <g transform='scale(1 -1) translate(0 -$ymax)'>\n" .
    " <path d='$path'\n" .
    " style='fill: #77FFCC; stroke: #000000'/>\n\n" .
    " </g>\n",
    "</svg>\n";
	close $fh;

	my $bitmap = Image::Magick -> new();
	my $result  = $bitmap -> Read($fh -> filename() );

	die $result if $result;

	# We have to set the background to none so when the bitmap is rotated,
	# the areas filled in where the glyph is moved from are left as white.

	$result = $bitmap -> Set(background => 'None');

	die $result if $result;

	# We set white as transparent so this bitmap has no background, so that
	# when it's overlayed on the original image, only the glyph is visible.

	$result = $bitmap -> Transparent(color => 'White');

	die $result if $result;

	$result = $bitmap -> Rotate($rotation);

	die $result if $result;

	return $bitmap;

}	# End of glyph2svg2bitmap.

# ------------------------------------------------

}	# End of package.

1;

=head1 NAME

C<Image::Magick::PolyText::FreeType> - Draw text along a polyline using FreeType and Image::Magick

=head1 Synopsis

	my $polytext = Image::Magick::PolyText::FreeType -> new
	({
	debug        => 0,
	fill         => 'Red',
	image        => $image,
	pointsize    => 16,
	rotate       => 1,
	slide        => 0.1,
	stroke       => 'Red',
	strokewidth  => 1,
	text         => 'Draw.text.along.a.polyline', # Can't use spaces!
	x            => [0, 1, 2, 3, 4],
	'y'          => [0, 1, 2, 3, 4], # y eq tr so syntax highlighting stuffed without ''.
	});

	$polytext -> annotate();

Warning: Experimental code - Do not use.

=head1 Description

C<Image::Magick::PolyText::FreeType> is a pure Perl module.

It is a convenient wrapper around C<Image::Magick's Annotate()> method, for drawing text along a polyline.

Warning: Experimental code - Do not use.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

Warning: Experimental code - Do not use.

new(...) returns an C<Image::Magick::PolyText::FreeType> object.

This is the class's contructor.

Usage: Image::Magick::PolyText::FreeType -> new({...}).

This method takes a hashref of parameters.

For each parameter you wish to use, call new as new({param_1 => value_1, ...}).

=over 4

=item debug

Takes either 0 or 1 as its value.

The default value is 0.

When set to 1, the module writes to STDOUT, and plots various stuff on your image.

This parameter is optional.

=item fill

Takes an C<Image::Magick> color as its value.

The default value is 'Red'.

The value is passed to C<Image::Magick's Annotate()> method.

This parameter is optional.

=item image

Takes an C<Image::Magick> object as its value.

There is no default value.

This parameter is mandatory.

=item pointsize

Takes an integer as its value.

The default value is 16.

The value is passed to C<Image::Magick's Annotate()> method.

This parameter is optional.

=item rotate

Takes either 0 or 1 as its value.

The default value is 1.

When set to 0, the module does not rotate any characters in the text.

When set to 1, the module rotates each character in the text to match the tangent of the polyline
at the 'current' (x, y) position.

This parameter is optional.

=item slide

Takes a real number in the range 0.0 to 1.0 as its value.

The default value is 0.0.

The value represents how far along the polyline (0.0 = 0%, 1.0 = 100%) to slide the first character of the text.

The parameter is optional.

=item stroke

Takes an C<Image::Magick> color as its value.

The default value is 'Red'.

The value is passed to C<Image::Magick's Annotate()> method.

This parameter is optional.

=item strokewidth

Takes an integer as its value.

The default value is 1.

The value is passed to C<Image::Magick's Annotate()> method.

This parameter is optional.

=item text

Takes a string of characters as its value.

There is no default value.

This text is split character by character, and each character is drawn with a separate call to
C<Image::Magick's Annotate()> method. This is a very slow process. You have been warned.

This parameter is mandatory.

=item x

Takes an array ref of x (co-ordinate) values as its value.

There is no default value.

These co-ordinates are the x-axis values of the polyline.

This parameter is mandatory.

=item y

Takes an array ref of y (abcissa) values as its value.

There is no default value.

These abcissa are the y-axis values of the polyline.

This parameter is mandatory.

=back

=head1 Method: annotate()

This method writes the text on to your image.

=head1 Method: draw({options})

This method draws a line through the data points.

The default line color is green.

The options are a hash ref which is passed to C<Image::Magick's Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> draw({stroke => 'blue'});

=head1 Method: highlight_data_points({options})

This method draws little (5x5 pixel) rectangles centered on the data points.

The default rectangle color is red.

The options are a hash ref which is passed to C<Image::Magick's Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> highlight_data_points({stroke => 'black'});

=head1 Example code

See the file examples/ptf.pl in the distro.

=head1 Required Modules

=over 4

=item Class::Std

=item File::Temp

=item Font::FreeType

=item Math::Bezier

=item Math::Interpolate

=item POSIX

=item Readonly

=back

=head1 Changes

See the ChangeLog file.

=head1 Author

C<Image::Magick::PolyText::FreeType> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2007.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

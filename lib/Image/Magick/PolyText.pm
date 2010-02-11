package Image::Magick::PolyText;
{
use strict;
use warnings;

use Class::Std;
use Math::Bezier;
use Math::Interpolate;
use Readonly;

our $VERSION = '1.0.3';

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

	if ($debug{$id})
	{
		$self -> dump();
	}

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
		$result   = $image{$id} -> Annotate
		(
		fill        => $fill{$id},
		pointsize   => $pointsize{$id},
		rotate      => $rotation,
		stroke      => $stroke{$id},
		strokewidth => $strokewidth{$id},
		text        => $text[$i],
		x           => $x,
		'y'         => $y, # y eq tr, so syntax highlighting stuffed without ''.
		);

		die $result if $result;

		$x += $pointsize{$id};
	}

}	# End of annotate.

# ------------------------------------------------

sub draw : CUMULATIVE
{
	my $self = shift @_;
	my $arg  = shift @_;
	my $id   = ident $self;

	my $i;
	my $s = '';

	for $i (0 .. $#{$x{$id} })
	{
		$s .= "$x{$id}[$i],$y{$id}[$i] ";
	}

	my %option =
	(
		fill        => 'None',
	 	points      => $s,
		primitive   => 'polyline',
		stroke      => 'Green',
		strokewidth => 1,
		map{(lc $_, $$arg{$_})} keys %$arg,
	);

	my $result = $image{$id} -> Draw(%option);

	die $result if $result;

}	# End of draw.

# ------------------------------------------------

sub dump
{
	my $self = shift @_;

	print $self -> _DUMP();
	$self -> dump_font_metrics();
	$self -> highlight_data_points();

}	# End of dump.

# ------------------------------------------------

sub dump_font_metrics
{
	my $self        = shift @_;
	my $id          = ident $self;
	my %metric_name =
	(
	 0  => 'character width',
	 1  => 'character height',
	 2  => 'ascender',
	 3  => 'descender',
	 4  => 'text width',
	 5  => 'text height',
	 6  => 'maximum horizontal advance',
	 7  => 'bounds.x1',
	 8  => 'bounds.y1',
	 9  => 'bounds.x2',
	 10 => 'bounds.y2',
	 11 => 'origin.x',
	 12 => 'origin.y',
	);

	my @metric = $image{$id} -> QueryFontMetrics
	(
	pointsize   => $pointsize{$id},
	strokewidth => $strokewidth{$id},
	text        => 'W',
	);

	print map{"$metric_name{$_}: $metric[$_]. \n"} 0 .. $#metric;
	print "\n";

	my $i;
	my $left_x;
	my $left_y;
	my $result;
	my $right_x;
	my $right_y;

	for ($i = 0; $i <= $#{$x{$id} }; $i++)
	{
		$left_x  = $x{$id}[$i] - $metric[7];
		$left_y  = $y{$id}[$i] - $metric[8];
		$right_x = $x{$id}[$i] + $metric[9];
		$right_y = $y{$id}[$i] + $metric[10];
		$result  = $image{$id} -> Draw
		(
		fill        => 'None',
		points      => "$left_x,$left_y $right_x,$right_y",
		primitive   => 'rectangle',
		stroke      => 'Blue',
		strokewidth => 1,
		);

		die $result if $result;
	}

}	# End of dump_font_metrics.

# ------------------------------------------------

sub highlight_data_points
{
	my $self   = shift @_;
	my $arg    = shift @_;
	my $id     = ident $self;
	my %option =
	(
		fill        => 'None',
		primitive   => 'rectangle',
		stroke      => 'Red',
		strokewidth => 1,
		map{(lc $_, $$arg{$_})} keys %$arg,
	);

	my $i;
	my $left_x;
	my $left_y;
	my $result;
	my $right_x;
	my $right_y;

	for ($i = 0; $i <= $#{$x{$id} }; $i++)
	{
		$left_x           = $x{$id}[$i] - 2;
		$left_y           = $y{$id}[$i] - 2;
		$right_x          = $x{$id}[$i] + 2;
		$right_y          = $y{$id}[$i] + 2;
		$option{'points'} = "$left_x,$left_y $right_x,$right_y";
		$result           = $image{$id} -> Draw(%option);

		die $result if $result;
	}

}	# End of highlight_data_points.

# ------------------------------------------------

}	# End of package.

1;

=head1 NAME

C<Image::Magick::PolyText> - Draw text along a polyline

=head1 Synopsis

	my $polytext = Image::Magick::PolyText -> new
	({
	debug        => 0,
	fill         => 'Red',
	image        => $image,
	pointsize    => 16,
	rotate       => 1,
	slide        => 0.1,
	stroke       => 'Red',
	strokewidth  => 1,
	text         => 'Draw text along a polyline',
	x            => [0, 1, 2, 3, 4],
	'y'          => [0, 1, 2, 3, 4], # y eq tr so emacs' syntax highlighting is stuffed without ''.
	});

	$polytext -> annotate();

=head1 Description

C<Image::Magick::PolyText> is a pure Perl module.

It is a convenient wrapper around C<Image::Magick's Annotate()> method, for drawing text along a polyline.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns an C<Image::Magick::PolyText> object.

This is the class's contructor.

Usage: Image::Magick::PolyText -> new({...}).

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

These co-ordinates are the x-axis values of the known points along the polyline.

This parameter is mandatory.

=item y

Takes an array ref of y (abcissa) values as its value.

There is no default value.

These abcissae are the y-axis values of the known points along the polyline.

This parameter is mandatory.

=back

=head1 Method: annotate()

This method writes the text on to your image.

=head1 Method: draw({options})

This method draws straight lines from data point to data point.

The default line color is Green.

The options are a hash ref which is passed to C<Image::Magick's Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> draw({stroke => 'Blue'});

=head1 Method: highlight_data_points({options})

This method draws little (5x5 pixel) rectangles centered on the data points.

The default rectangle color is Red.

The options are a hash ref which is passed to C<Image::Magick's Draw()> method, so any option
acceptable to C<Draw()> is acceptable here.

A typical usage would be $polytext -> highlight_data_points({stroke => 'Black'});

=head1 Example code

See the file examples/pt.pl in the distro.

=head1 Required Modules

=over 4

=item Class::Std

=item Math::Bezier

=item Math::Interpolate

=item Readonly

=back

=head1 Changes

See the ChangeLog file.

=head1 Author

C<Image::Magick::PolyText> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2007.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2007, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
	($] ge '5.005') ?
	(
		'AUTHOR'   => 'Ron Savage (ron@savage.net.au)',
		'ABSTRACT' => 'Draw text along a polyline',
    ) : (),
	clean          =>
	{
		FILES      => 'blib/* Makefile MANIFEST Image-Magick-PolyText-*'
	},
	dist           =>
	{
		COMPRESS   => 'gzip',
		SUFFIX     => 'gz'
	},
	DISTNAME       => 'Image-Magick-PolyText',
	NAME           => 'Image::Magick::PolyText',
	PL_FILES       => {},
	PREREQ_PM      =>
	{
		Carp              => 0,
		Class::Std        => 0,
		Image::Magick     => 0,
		Math::Bezier      => 0,
		Math::Interpolate => 0,
		Readonly          => 0,
	},
	VERSION_FROM   => 'lib/Image/Magick/PolyText.pm',
);

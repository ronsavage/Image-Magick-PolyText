use Module::Build;

Module::Build -> new
(
	module_name    => 'Image::Magick::PolyText',
	license        => 'artistic',
	dist_abstract  => 'Draw text along a polyline',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		Carp              => 0,
		Image::Magick     => 0,
		Math::Bezier      => 0,
		Math::Interpolate => 0,
		Readonly          => 0,
	},
) -> create_build_script();

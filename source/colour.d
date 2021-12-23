module colour;

import v3;

union Colour
{
	V3 _c;
	struct
	{
		double r, g, b;
	}

	alias _c this;

	this(double r, double g, double b)
	{
		_c = V3(r, g, b);
	}

	uint toUint() const
	{
		// dfmt off
		return
		(cast(int)(1 * 255)) << 24 |
		(cast(int)(b * 255)) << 16 |
		(cast(int)(g * 255)) <<  8 |
		(cast(int)(r * 255)) <<  0;
	// dfmt on
	}

	Colour gammaCorrect() const
	{
		import std.math : sqrt;

		return Colour(sqrt(r), sqrt(g), sqrt(b));
	}

	static Colour white()
	{
		return Colour(1.0, 1.0, 1.0);
	}

	static Colour black()
	{
		return Colour(0.0, 0.0, 0.0);
	}

	static Colour red()
	{
		return Colour(1.0, 0.0, 0.0);
	}

	static Colour green()
	{
		return Colour(0.0, 1.0, 0.0);
	}

	static Colour blue()
	{
		return Colour(0.0, 0.0, 1.0);
	}

	static Colour yellow()
	{
		return Colour(1.0, 1.0, 0.0);
	}

	static Colour cyan()
	{
		return Colour(0.0, 1.0, 1.0);
	}

	static Colour magenta()
	{
		return Colour(1.0, 0.0, 1.0);
	}

	static Colour random()
	{
		import std.random : uniform01;

		return Colour(uniform01, uniform01, uniform01);
	}

	static Colour random(double min, double max)
	in (min >= 0.0)
	in (max <= 1.0)
	{
		import std.random : uniform;

		return Colour(uniform(min, max), uniform(min, max), uniform(min, max));
	}
}

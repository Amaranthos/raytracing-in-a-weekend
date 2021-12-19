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

	uint toUint()
	{
		// dfmt off
		return
		(cast(int)(1 * 255)) << 24 |
		(cast(int)(b * 255)) << 16 |
		(cast(int)(g * 255)) <<  8 |
		(cast(int)(r * 255)) <<  0;
	// dfmt on
	}

	uint toUint(int samplesPerPxl)
	{
		auto c = cast(Colour)(this * (1.0 / samplesPerPxl));

		// dfmt off
		return
		(cast(int)(  1 * 255)) << 24 |
		(cast(int)(c.b * 255)) << 16 |
		(cast(int)(c.g * 255)) <<  8 |
		(cast(int)(c.r * 255)) <<  0;
	// dfmt on
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
}

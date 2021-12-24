module texture;

import colour;
import v3;

interface Texture
{
	Colour value(double u, double v, in V3 point) const;
}

class SolidColour : Texture
{
	Colour colour;

	this(in Colour colour)
	{
		this.colour = colour;
	}

	Colour value(double u, double v, in V3 point) const
	{
		return colour;
	}
}

class Checker : Texture
{
	Texture even;
	Texture odd;

	this(Texture even, Texture odd)
	{
		this.even = even;
		this.odd = odd;
	}

	this(in Colour even, in Colour odd)
	{
		this.even = new SolidColour(even);
		this.odd = new SolidColour(odd);
	}

	Colour value(double u, double v, in V3 point) const
	{
		import std.math : sin;

		const sines = sin(10 * point.x) * sin(10 * point.y) * sin(10 * point.z);
		return sines < 0 ? odd.value(u, v, point) : even.value(u, v, point);
	}
}

class Noise : Texture
{
	double scale;

	this(double scale)
	{
		this.scale = scale;
	}

	Colour value(double u, double v, in V3 point) const
	{
		import perlin : noise;

		return cast(Colour)(Colour.white * 0.5 * (1.0 + noise(point * scale)));
	}
}

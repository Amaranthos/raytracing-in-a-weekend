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
		import perlin : turb;
		import std.math : sin;

		return cast(Colour)(Colour.white * 0.5 * (1 + sin(scale * point.z + 10 * turb(point))));
	}
}

class Image : Texture
{
	enum int bytesPerPixel = 3;
	ubyte* data;
	uint width, height;
	uint pitch;

	this(in string filename)
	{
		import bindbc.sdl : IMG_Load, SDL_Surface, SDL_PIXELFORMAT_ARGB8888;
		import std.string : toStringz;

		SDL_Surface* img = IMG_Load(filename.toStringz);

		if (img)
		{
			data = cast(ubyte*) img.pixels;
			width = img.w;
			height = img.h;
			pitch = img.pitch;
		}
	}

	Colour value(double u, double v, in V3 point) const
	{
		if (data is null)
			return Colour.magenta;

		import std.algorithm : clamp;

		u = u.clamp(0.0, 1.0);
		v = 1.0 - v.clamp(0.0, 1.0);

		auto i = cast(int)(u * width);
		auto j = cast(int)(v * height);

		i = i.clamp(0, width - 1);
		j = j.clamp(0, height - 1);

		enum colourScale = 1.0 / 255.0;
		auto pixel = data + j * pitch + i * bytesPerPixel;
		return cast(Colour)(Colour(pixel[0], pixel[1], pixel[2]) * colourScale);
	}
}

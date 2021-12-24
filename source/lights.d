module lights;

import colour;
import hit_record;
import material;
import ray;
import texture;
import v3;

class DiffuseLight : Material
{
	Texture emit;

	this(Texture emit)
	{
		this.emit = emit;
	}

	this(Colour colour)
	{
		this.emit = new SolidColour(colour);
	}

	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered) const
	{
		return false;
	}

	Colour emitted(double u, double v, in V3 point) const
	{
		return emit.value(u, v, point);
	}
}

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

	override Colour emitted(in Ray ray, in HitRecord rec, double u, double v, in V3 point) const
	{
		if (rec.frontFace)
		{
			return emit.value(u, v, point);
		}
		else
		{
			return Colour.black;
		}
	}
}

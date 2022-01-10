module onb;

import std.math : abs;

import v3;

struct ONB
{
	V3 u, v, w;

	V3 local(double a, double b, double c) const
	{
		return a * u + b * v + c * w;
	}

	V3 local(in V3 a) const
	{
		return local(a.x, a.y, a.z);
	}

	static ONB fromW(in V3 n)
	{
		V3 w = n.normalised;
		V3 a = (abs(w.x) > 0.9) ? V3.up : V3.right;
		V3 v = w.cross(a).normalised;
		V3 u = w.cross(v);

		return ONB(u, v, w);
	}
}

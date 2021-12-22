module camera;

import ray;
import v3;

class Camera
{
	private
	{
		V3 origin;
		V3 hori;
		V3 vert;
		V3 blCorner;
	}

	this(V3 pos, V3 lookAt, V3 up, double vfov, double aspectRatio)
	{
		import math : deg2Rad;
		import std.math : tan;

		const theta = vfov.deg2Rad;
		const h = tan(theta / 2);
		const viewHeight = 2.0 * h;
		const viewWidth = aspectRatio * viewHeight;

		const w = (pos - lookAt).normalised;
		const u = up.cross(w).normalised;
		const v = w.cross(u);

		origin = pos;
		hori = viewWidth * u;
		vert = viewHeight * v;
		blCorner = origin - hori / 2.0 - vert / 2.0 - w;
	}

	Ray ray(in double s, in double t)
	{
		return Ray(origin, blCorner + s * hori + t * vert - origin);
	}
}

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
		V3 u, v, w;
		double lensRadius;
	}

	this(V3 pos, V3 lookAt, V3 up, double vfov, double aspectRatio, double aperture, double focusDistance)
	{
		import math : deg2Rad;
		import std.math : tan;

		const theta = vfov.deg2Rad;
		const h = tan(theta / 2);
		const viewHeight = 2.0 * h;
		const viewWidth = aspectRatio * viewHeight;

		w = (pos - lookAt).normalised;
		u = up.cross(w).normalised;
		v = w.cross(u);

		origin = pos;
		hori = focusDistance * viewWidth * u;
		vert = focusDistance * viewHeight * v;
		blCorner = origin - hori / 2.0 - vert / 2.0 - focusDistance * w;

		lensRadius = aperture / 2;
	}

	Ray ray(in double s, in double t)
	{
		V3 rd = lensRadius * randomPointInUnitDisk;
		V3 offset = u * rd.x + v * rd.y;

		return Ray(origin + offset, blCorner + s * hori + t * vert - origin - offset);
	}
}

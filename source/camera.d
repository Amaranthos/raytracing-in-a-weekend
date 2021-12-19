module camera;

import ray;
import v3;

enum double aspectRatio = 16.0 / 9.0;
enum double viewHeight = 2.0;
enum double viewWidth = aspectRatio * viewHeight;
enum double focalLength = 1.0;

class Camera
{
	private
	{
		V3 origin;
		V3 hori;
		V3 vert;
		V3 blCorner;
	}

	this()
	{
		origin = V3.zero;
		hori = V3(viewWidth, 0.0, 0.0);
		vert = V3(0.0, viewHeight, 0.0);
		blCorner = origin - hori / 2.0 - vert / 2.0 - V3(0.0, 0.0, focalLength);

		import std.stdio : writefln;

		writefln!"%s %s %s %s"(origin, hori, vert, blCorner);
	}

	Ray ray(in double u, in double v)
	{
		return Ray(origin, blCorner + u * hori + v * vert - origin);
	}
}

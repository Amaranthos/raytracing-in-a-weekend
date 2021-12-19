module geometry;

import ray;
import v3;

struct HitRecord
{
	V3 pos;
	V3 norm;
	double t;
	bool frontFace;

	void setFaceNormal(in Ray ray, in V3 outwardNorm)
	{
		frontFace = ray.dir.dot(outwardNorm) < 0;
		norm = frontFace ? outwardNorm : -outwardNorm;
	}
}

interface Geometry
{
	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec) const;
}

class Sphere : Geometry
{
	V3 pos;
	double radius;

	this(V3 pos, double radius)
	{
		this.pos = pos;
		this.radius = radius;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec) const
	{
		V3 oc = ray.origin - pos;
		auto a = ray.dir.magnitudeSquared;
		auto halfB = oc.dot(ray.dir);
		auto c = oc.magnitudeSquared - radius ^^ 2;
		auto discriminant = halfB ^^ 2 - a * c;
		if (discriminant < 0)
			return false;

		import std.math : sqrt;

		auto sqrtd = discriminant.sqrt;
		auto root = (-halfB - sqrtd) / a;
		if (root < tMin || tMax < root)
		{
			root = (-halfB + sqrtd) / a;
			if (root < tMin || tMax < root)
			{
				return false;
			}
		}

		rec.t = root;
		rec.pos = ray.at(rec.t);
		rec.setFaceNormal(ray, (rec.pos - pos) / radius);

		return true;
	}
}

bool hit(in Geometry[] geometries, in Ray ray, double tMin, double tMax, out HitRecord rec)
{
	HitRecord subRec;
	bool hit;
	auto closest = tMax;

	foreach (geometry; geometries)
	{
		if (geometry.hit(ray, tMin, tMax, subRec))
		{
			hit = true;
			closest = subRec.t;
			rec = subRec;
		}
	}

	return hit;
}

module geometry;

import std.typecons;

import hit_record;
import material;
import ray;
import v3;

interface Geometry
{
	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec);
}

class Sphere : Geometry
{
	V3 pos;
	double radius;
	Material mat;

	this(V3 pos, double radius, Material mat)
	{
		this.pos = pos;
		this.radius = radius;
		this.mat = mat;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
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
		rec.mat = mat;

		return true;
	}
}

bool hit(Geometry[] geometries, in Ray ray, double tMin, double tMax, out HitRecord rec)
{
	HitRecord subRec;
	bool hit;
	auto closest = tMax;

	foreach (ref geometry; geometries)
	{
		if (geometry.hit(ray, tMin, closest, subRec))
		{
			hit = true;
			closest = subRec.t;
			rec = subRec;
		}
	}

	return hit;
}

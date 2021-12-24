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

class MovingSphere : Geometry
{
	V3 p0, p1;
	double t0, t1;
	double radius;
	Material mat;

	this(V3 p0, V3 p1, double t0, double t1, double radius, Material mat)
	{
		this.p0 = p0;
		this.p1 = p1;
		this.t0 = t0;
		this.t1 = t1;
		this.radius = radius;
		this.mat = mat;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		V3 oc = ray.origin - pos(ray.time);
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
		rec.setFaceNormal(ray, (rec.pos - pos(ray.time)) / radius);
		rec.mat = mat;

		return true;
	}

	V3 pos(in double t) const
	{
		import math : lerp;

		// return lerp(p0, p1, ((t - t0) / (t1 - t0)));

		return p0 + ((t - t0) / (t1 - t0)) * (p1 - p0);
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

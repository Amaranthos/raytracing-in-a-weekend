module geometry;

import std.typecons;

import aabb;
import hit_record;
import material;
import ray;
import v3;

interface Geometry
{
	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec);
	bool boundingBox(double t0, double t1, out AABB boundingBox) const;
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
		const outwardNorm = (rec.pos - pos) / radius;
		rec.setFaceNormal(ray, outwardNorm);
		rec.mat = mat;
		getSphereUVs(rec.norm, rec.u, rec.v);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		const rad = V3(radius, radius, radius);
		boundingBox = AABB(pos - rad, pos + rad);
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
		const outwardNorm = (rec.pos - pos(ray.time)) / radius;
		rec.setFaceNormal(ray, outwardNorm);
		rec.mat = mat;
		getSphereUVs(rec.norm, rec.u, rec.v);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		const rad = V3(radius, radius, radius);
		auto box0 = AABB(pos(t0) - rad, pos(t0) + rad);
		auto box1 = AABB(pos(t1) - rad, pos(t1) + rad);
		boundingBox = box0.expand(box1);
		return true;
	}

	V3 pos(in double t) const
	{
		import math : lerp;

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

bool boundingBox(Geometry[] geometries, double t0, double t1, out AABB boundingBox)
{
	import std.array : empty;

	if (geometries.empty)
		return false;

	AABB temp;

	foreach (idx, ref geometry; geometries)
	{
		if (!geometry.boundingBox(t0, t1, temp))
			return false;
		boundingBox = idx == 0 ? temp : boundingBox.expand(temp);
	}

	return true;
}

void getSphereUVs(in V3 point, out double u, out double v)
{
	import std.math : acos, atan2, PI;

	auto theta = acos(-point.y);
	auto phi = atan2(-point.z, point.x) + PI;

	u = phi / (2 * PI);
	v = theta / PI;
}

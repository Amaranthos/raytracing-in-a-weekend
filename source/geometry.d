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

class PlaneXY : Geometry
{
	Material mat;
	double x0, x1, y0, y1, k;

	this(double x0, double x1, double y0, double y1, double k, Material mat)
	{
		this.x0 = x0;
		this.x1 = x1;
		this.y0 = y0;
		this.y1 = y1;
		this.k = k;
		this.mat = mat;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		auto t = (k - ray.origin.z) / ray.dir.z;
		if (t < tMin || t > tMax)
			return false;

		auto x = ray.origin.x + t * ray.dir.x;
		auto y = ray.origin.y + t * ray.dir.y;

		if (x < x0 || x > x1 || y < y0 || y > y1)
			return false;

		auto outwardNorm = V3.forward;
		rec.u = (x - x0) / (x1 - x0);
		rec.v = (y - y0) / (y1 - y0);
		rec.t = t;
		rec.setFaceNormal(ray, outwardNorm);
		rec.mat = mat;
		rec.pos = ray.at(t);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		boundingBox = AABB(V3(x0, y0, k - 0.0001), V3(x1, y1, k + 0.0001));
		return true;
	}
}

class PlaneXZ : Geometry
{
	Material mat;
	double x0, x1, z0, z1, k;

	this(double x0, double x1, double z0, double z1, double k, Material mat)
	{
		this.x0 = x0;
		this.x1 = x1;
		this.z0 = z0;
		this.z1 = z1;
		this.k = k;
		this.mat = mat;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		auto t = (k - ray.origin.y) / ray.dir.y;
		if (t < tMin || t > tMax)
			return false;

		auto x = ray.origin.x + t * ray.dir.x;
		auto z = ray.origin.z + t * ray.dir.z;

		if (x < x0 || x > x1 || z < z0 || z > z1)
			return false;

		auto outwardNorm = V3.up;
		rec.u = (x - x0) / (x1 - x0);
		rec.v = (z - z0) / (z1 - z0);
		rec.t = t;
		rec.setFaceNormal(ray, outwardNorm);
		rec.mat = mat;
		rec.pos = ray.at(t);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		boundingBox = AABB(V3(x0, k - 0.0001, z0), V3(x1, k + 0.0001, z1));
		return true;
	}
}

class PlaneYZ : Geometry
{
	Material mat;
	double y0, y1, z0, z1, k;

	this(double y0, double y1, double z0, double z1, double k, Material mat)
	{
		this.y0 = y0;
		this.y1 = y1;
		this.z0 = z0;
		this.z1 = z1;
		this.k = k;
		this.mat = mat;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		auto t = (k - ray.origin.x) / ray.dir.x;
		if (t < tMin || t > tMax)
			return false;

		auto y = ray.origin.y + t * ray.dir.y;
		auto z = ray.origin.z + t * ray.dir.z;

		if (y < y0 || y > y1 || z < z0 || z > z1)
			return false;

		auto outwardNorm = V3.right;
		rec.u = (y - y0) / (y1 - y0);
		rec.v = (z - z0) / (z1 - z0);
		rec.t = t;
		rec.setFaceNormal(ray, outwardNorm);
		rec.mat = mat;
		rec.pos = ray.at(t);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		boundingBox = AABB(V3(k - 0.0001, y0, z0), V3(k + 0.0001, y1, z1));
		return true;
	}
}

class Box : Geometry
{
	V3 minimum;
	V3 maximum;
	Geometry[] sides;

	this(in V3 min, in V3 max, Material mat)
	{
		minimum = min;
		maximum = max;

		sides ~= new PlaneXY(min.x, max.x, min.y, max.y, max.z, mat);
		sides ~= new PlaneXY(min.x, max.x, min.y, max.y, min.z, mat);

		sides ~= new PlaneXZ(min.x, max.x, min.z, max.z, max.y, mat);
		sides ~= new PlaneXZ(min.x, max.x, min.z, max.z, min.y, mat);

		sides ~= new PlaneYZ(min.y, max.y, min.z, max.z, max.x, mat);
		sides ~= new PlaneYZ(min.y, max.y, min.z, max.z, min.x, mat);
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		return sides.hit(ray, tMin, tMax, rec);
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		boundingBox = AABB(minimum, maximum);

		return true;
	}
}

class Translate : Geometry
{
	Geometry geo;
	V3 offset;

	this(Geometry geo, in V3 translation)
	{
		this.geo = geo;
		this.offset = translation;
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		Ray moved = Ray(ray.origin - offset, ray.dir, ray.time);
		if (!geo.hit(moved, tMin, tMax, rec))
		{
			return false;
		}

		rec.pos += offset;
		rec.setFaceNormal(moved, rec.norm);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		if (!geo.boundingBox(t0, t1, boundingBox))
			return false;

		boundingBox = AABB(boundingBox.minimum + offset, boundingBox.maximum + offset);
		return true;
	}
}

class RotateY : Geometry
{
	Geometry geo;
	double sinTheta;
	double cosTheta;
	bool hasBox;
	AABB bbox;

	this(Geometry geo, double angle)
	{
		this.geo = geo;

		import math : deg2Rad;
		import std.math : sin, cos;
		import std.algorithm : min, max;

		auto radians = angle.deg2Rad;
		sinTheta = radians.sin;
		cosTheta = radians.cos;
		hasBox = geo.boundingBox(0, 1, bbox);

		V3 minimum = V3.infinity;
		V3 maximum = -V3.infinity;

		foreach (i; 0 .. 2)
		{
			foreach (j; 0 .. 2)
			{
				foreach (k; 0 .. 2)
				{
					auto x = i * bbox.maximum.x + (1 - i) * bbox.minimum.x;
					auto y = j * bbox.maximum.y + (1 - j) * bbox.minimum.y;
					auto z = k * bbox.maximum.z + (1 - k) * bbox.minimum.z;

					auto newX = cosTheta * x + sinTheta * z;
					auto newZ = -sinTheta * x + cosTheta * z;

					V3 tester = V3(newX, y, newZ);

					foreach (c; 0 .. 3)
					{
						minimum.e[c] = min(minimum[c], tester[c]);
						maximum.e[c] = max(maximum[c], tester[c]);
					}
				}
			}
		}

		bbox = AABB(minimum, maximum);
	}

	bool hit(in Ray ray, double tMin, double tMax, out HitRecord rec)
	{
		V3 origin = ray.origin;
		V3 dir = ray.dir;

		origin.x = cosTheta * ray.origin.x - sinTheta * ray.origin.z;
		origin.z = sinTheta * ray.origin.x + cosTheta * ray.origin.z;

		dir.x = cosTheta * ray.dir.x - sinTheta * ray.dir.z;
		dir.z = sinTheta * ray.dir.x + cosTheta * ray.dir.z;

		Ray rotated = Ray(origin, dir, ray.time);

		if (!geo.hit(rotated, tMin, tMax, rec))
			return false;

		V3 p = rec.pos;
		V3 norm = rec.norm;

		p.x = cosTheta * rec.pos.x + sinTheta * rec.pos.z;
		p.z = -sinTheta * rec.pos.x + cosTheta * rec.pos.z;

		norm.x = cosTheta * rec.norm.x + sinTheta * rec.norm.z;
		norm.z = -sinTheta * rec.norm.x + cosTheta * rec.norm.z;

		rec.pos = p;
		rec.setFaceNormal(rotated, norm);

		return true;
	}

	bool boundingBox(double t0, double t1, out AABB boundingBox) const
	{
		boundingBox = bbox;
		return hasBox;
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

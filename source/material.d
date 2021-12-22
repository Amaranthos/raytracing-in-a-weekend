module material;

import colour;
import hit_record;
import ray;
import v3;

interface Material
{
	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered) const;
}

class Lambertian : Material
{
	Colour albedo;

	this(Colour albedo)
	{
		this.albedo = albedo;
	}

	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered) const
	{
		V3 scatterDir = rec.norm + randomUnitVector;
		// const scatterDir = rec.norm + randomPointInUnitSphere;
		// const scatterDir = randomInHemisphere(rec.norm);

		if (scatterDir.nearZero)
		{
			scatterDir = rec.norm;
		}

		scattered = Ray(rec.pos, scatterDir);
		attenuation = albedo;
		return true;
	}
}

class Metal : Material
{
	Colour albedo;
	double roughness;

	this(Colour albedo, double roughness)
	{
		this.albedo = albedo;
		this.roughness = roughness < 1 ? roughness : 1;
	}

	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered) const
	{
		V3 reflected = ray.dir.normalised.reflect(rec.norm);
		scattered = Ray(rec.pos, reflected + roughness * randomPointInUnitSphere);
		attenuation = albedo;
		return (scattered.dir.dot(rec.norm) > 0);
	}
}

class Dielectric : Material
{
	double rIdx;

	this(double refractiveIndex)
	{
		this.rIdx = refractiveIndex;
	}

	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered) const
	{
		attenuation = Colour.white;
		double refractiveRatio = rec.frontFace ? (1.0 / rIdx) : rIdx;

		V3 unitDir = ray.dir.normalised;

		import std.algorithm : min;
		import std.math : sqrt;

		const cosTheta = min(-unitDir.dot(rec.norm), 1.0);
		const sinTheta = sqrt(1.0 - cosTheta ^^ 2);

		V3 direction = (refractiveRatio * sinTheta > 1.0) ? unitDir.reflect(
			rec.norm) : unitDir.refract(rec.norm, refractiveRatio);

		scattered = Ray(rec.pos, direction);
		return true;
	}
}

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

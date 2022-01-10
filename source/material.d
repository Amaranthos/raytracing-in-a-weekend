module material;

import std.math : PI;

import colour;
import hit_record;
import onb;
import ray;
import texture;
import v3;

class Material
{
	bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered, out double pdf) const
	{
		return false;
	};

	double scatteringPDF(in Ray ray, in HitRecord rec, in Ray scattered)
	{
		return 0.0;
	}

	Colour emitted(in Ray ray, in HitRecord rec, double u, double v, in V3 point) const
	{
		return Colour.black;
	};
}

class Lambertian : Material
{
	Texture albedo;

	this(Colour albedo)
	{
		this.albedo = new SolidColour(albedo);
	}

	this(Texture albedo)
	{
		this.albedo = albedo;
	}

	override bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered, out double pdf) const
	{
		ONB uvw = ONB.fromW(rec.norm);
		auto direction = uvw.local(randomCosineDirection());

		scattered = Ray(rec.pos, direction.normalised, ray.time);
		attenuation = albedo.value(rec.u, rec.v, rec.pos);
		pdf = (uvw.w.dot(scattered.dir)) / PI;
		return true;
	}

	override double scatteringPDF(in Ray ray, in HitRecord rec, in Ray scattered)
	{
		auto cosine = rec.norm.dot(scattered.dir.normalised);
		return cosine < 0 ? 0 : cosine / PI;
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

	override bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered, out double pdf) const
	{
		V3 reflected = ray.dir.normalised.reflect(rec.norm);
		scattered = Ray(rec.pos, reflected + roughness * randomPointInUnitSphere, ray.time);
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

	override bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered, out double pdf) const
	{
		attenuation = Colour.white;
		double refractiveRatio = rec.frontFace ? (1.0 / rIdx) : rIdx;

		V3 unitDir = ray.dir.normalised;

		import std.algorithm : min;
		import std.math : sqrt;
		import std.random : uniform01;

		const cosTheta = min(rec.norm.dot(-unitDir), 1.0);
		const sinTheta = sqrt(1.0 - (cosTheta ^^ 2));

		bool willReflect = (refractiveRatio * sinTheta > 1.0) || reflectance(cosTheta, refractiveRatio) > uniform01;

		V3 direction = willReflect ? unitDir.reflect(
			rec.norm) : unitDir.refract(rec.norm, refractiveRatio);

		scattered = Ray(rec.pos, direction, ray.time);
		return true;
	}

	private double reflectance(double cosine, double refractiveRatio) const
	{
		const r0 = ((1 - refractiveRatio) / (1 + refractiveRatio)) ^^ 2;

		return r0 + (1 - r0) * ((1 - cosine) ^^ 5);
	}
}

class Isotropic : Material
{
	Texture albedo;

	this(Colour colour)
	{
		this.albedo = new SolidColour(colour);
	}

	this(Texture tex)
	{
		this.albedo = tex;
	}

	override bool scatter(in Ray ray, in HitRecord rec, out Colour attenuation, out Ray scattered, out double pdf) const
	{
		scattered = Ray(rec.pos, randomPointInUnitSphere, ray.time);
		attenuation = albedo.value(rec.u, rec.v, rec.pos);
		return true;
	}
}

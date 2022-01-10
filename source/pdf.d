module pdf;

import std.math : PI;
import std.random : uniform01;

import geometry;
import onb;
import v3;

abstract class PDF
{
	double value(in V3 direction);
	V3 generate();
}

class CosinePDF : PDF
{
	ONB uvw;

	this(in V3 w)
	{
		this.uvw = ONB.fromW(w);
	}

	override double value(in V3 direction)
	{
		auto cosine = direction.normalised.dot(uvw.w);
		return cosine <= 0.0 ? 0.0 : cosine / PI;
	}

	override V3 generate()
	{
		return uvw.local(randomCosineDirection());
	}
}

class HittablePDF : PDF
{
	V3 origin;
	Geometry geo;

	this(Geometry geo, in V3 origin)
	{
		this.origin = origin;
		this.geo = geo;
	}

	override double value(in V3 direction)
	{
		return geo.pdfValue(origin, direction);
	}

	override V3 generate()
	{
		return geo.random(origin);
	}
}

class MixturePDF : PDF
{
	PDF p1;
	PDF p2;

	this(PDF pdf1, PDF pdf2)
	{
		this.p1 = pdf1;
		this.p2 = pdf2;
	}

	override double value(in V3 direction)
	{
		return 0.5 * p1.value(direction) + 0.5 * p2.value(direction);
	}

	override V3 generate()
	{
		return uniform01 < 0.5 ? p1.generate() : p2.generate();
	}
}

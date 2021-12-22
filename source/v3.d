module v3;

union V3
{
	double[3] e;
	struct
	{
		double x;
		double y;
		double z;
	}

	this(double x, double y, double z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	this(double[3] e)
	{
		this.e = e;
	}

	V3 cross(in V3 rhs) const
	{
		return V3(
			y * rhs.z - z * rhs.y,
			z * rhs.x - x * rhs.z,
			x * rhs.y - y * rhs.x
		);
	}

	V3 hadamard(in V3 rhs) const
	{
		V3 r;
		r.x = x * rhs.x;
		r.y = y * rhs.y;
		r.z = z * rhs.z;
		return r;
	}

	double dot(in V3 rhs) const
	{
		return x * rhs.x + y * rhs.y + z * rhs.z;
	}

	double magnitudeSquared() const
	{
		return dot(this);
	}

	double magnitude() const
	{
		import std.math : sqrt;

		return magnitudeSquared.sqrt;
	}

	void magnitude(in double v)
	in (v != 0f)
	{
		this *= v / magnitude();
	}

	V3 normalised() const
	{
		import std.math : sqrt;

		V3 r = V3(e);
		r.magnitude = 1f;
		return r;
	}

	V3 lerp(V3 rhs, double t)
	{
		return (1.0 - t) * this + t * rhs;
	}

	bool nearZero() const
	{
		import std.math : abs;

		return x < double.epsilon
			&& y < double.epsilon
			&& z < double.epsilon;
	}

	V3 reflect(in V3 norm) const
	{
		return this - 2 * this.dot(norm) * norm;
	}

	V3 opBinary(string op)(in double rhs) const if (op == "*" || op == "/")
	{
		V3 r;
		mixin("r.x = x " ~ op ~ "rhs;");
		mixin("r.y = y " ~ op ~ "rhs;");
		mixin("r.z = z " ~ op ~ "rhs;");
		return r;
	}

	V3 opBinaryRight(string op)(in double rhs) const if (op == "*" || op == "/")
	{
		mixin("return this" ~ op ~ "rhs;");
	}

	V3 opBinary(string op)(in V3 rhs) const if (op == "+" || op == "-")
	{
		V3 r;
		mixin("r.x = x " ~ op ~ "rhs.x;");
		mixin("r.y = y " ~ op ~ "rhs.y;");
		mixin("r.z = z " ~ op ~ "rhs.z;");
		return r;
	}

	V3 opUnary(string op)() const if (op == "-")
	{
		return V3(-x, -y, -z);
	}

	V3 opOpAssign(string op)(in double rhs) if (op == "*" || op == "/")
	{
		mixin("x " ~ op ~ "= rhs;");
		mixin("y " ~ op ~ "= rhs;");
		mixin("z " ~ op ~ "= rhs;");
		return this;
	}

	V3 opOpAssign(string op)(in V3 rhs) if (op == "+" || op == "-")
	{
		mixin("x " ~ op ~ "= rhs.x;");
		mixin("y " ~ op ~ "= rhs.y;");
		mixin("z " ~ op ~ "= rhs.z;");
		return this;
	}

	string toString() const
	{
		import std.string : format;

		return e.format!"[%(%s,%)]";
	}

	static V3 zero()
	{
		return V3(0.0, 0.0, 0.0);
	}

	static V3 one()
	{
		return V3(1.0, 1.0, 1.0);
	}

	static V3 random()
	{
		import std.random : uniform01;

		return V3(uniform01, uniform01, uniform01);
	}

	static V3 random(in double min, in double max)
	{
		import std.random : uniform;

		return V3(uniform(min, max), uniform(min, max), uniform(min, max));
	}
}

V3 randomPointInUnitSphere()
{
	while (true)
	{
		auto p = V3.random(-1.0, 1.0);
		if (p.magnitudeSquared >= 1)
			continue;
		return p;
	}
}

V3 randomUnitVector()
{
	return randomPointInUnitSphere.normalised;
}

V3 randomInHemisphere(in V3 normal)
{
	V3 inUnitSphere = randomPointInUnitSphere;
	return normal.dot(inUnitSphere) > 0.0 ? inUnitSphere : -inUnitSphere;
}

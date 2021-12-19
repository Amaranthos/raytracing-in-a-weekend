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

	this(double[3] e)
	{
		this.e = e;
	}

	this(double x, double y, double z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	V3 cross(in V3 rhs) const
	{
		return V3(
			y * rhs.z - z * rhs.y,
			z * rhs.x - x * rhs.z,
			x * rhs.y - y * rhs.x
		);
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

	static V3 zero()
	{
		return V3(0.0, 0.0, 0.0);
	}

	static V3 one()
	{
		return V3(1.0, 1.0, 1.0);
	}
}

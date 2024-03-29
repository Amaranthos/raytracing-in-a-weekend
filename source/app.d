import bindbc.sdl;
import bindbc.opengl;

import std.math;
import std.random;
import std.stdio;
import std.string;

import bvh;
import camera;
import colour;
import exception;
import geometry;
import hit_record;
import lights;
import material;
import pdf;
import ray;
import texture;
import v3;
import volumes;

V3 camPos;
V3 lookAt;
auto vFov = 40.0;
auto aperture = 0.0;
Colour background = Colour.black;
uint maxDepth = 50;

double aspectRatio = 16.0 / 9.0;
uint samplesPerPixel = 100;

uint texWidth = 400;
uint texHeight;

enum uint winWidth = 1024;
enum uint winHeight = 1024;

GLuint textureId;
uint[] outBuffer;

Colour rayColour(in Ray ray, in Colour background, Geometry[] world, Geometry lights, in int depth)
{
	HitRecord rec;

	if (depth <= 0)
	{
		return Colour.black;
	}

	if (!world.hit(ray, 0.001, double.infinity, rec))
	{
		return background;
	}

	Ray scattered;
	Colour attenuation;
	Colour emitted = rec.mat.emitted(ray, rec, rec.u, rec.v, rec.pos);
	double pdfValue;
	Colour albedo;

	if (!rec.mat.scatter(ray, rec, albedo, scattered, pdfValue))
	{
		return emitted;
	}

	auto p0 = new HittablePDF(lights, rec.pos);
	auto p1 = new CosinePDF(rec.norm);
	MixturePDF mixedPdf = new MixturePDF(p0, p1);

	scattered = Ray(rec.pos, mixedPdf.generate, ray.time);
	pdfValue = mixedPdf.value(scattered.dir);

	return cast(Colour)(
		emitted +
			(albedo * rec.mat.scatteringPDF(ray, rec, scattered))
			.hadamard(rayColour(scattered, background, world, lights, depth - 1))
			/ pdfValue);
}

void loadScene()
{
	Geometry[] world;

	switch (0)
	{
	case 1:
		world = randomWorld();
		background = Colour(0.7, 0.8, 1.0);
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		aperture = 0.1;
		break;

	case 2:
		world = twoSpheres();
		background = Colour(0.7, 0.8, 1.0);
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		break;

	case 3:
		world = twoPerlinSpheres();
		background = Colour(0.7, 0.8, 1.0);
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		break;

	case 4:
		world = earth();
		background = Colour(0.7, 0.8, 1.0);
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		break;

	case 5:
		world = simpleLight();
		samplesPerPixel = 400;
		camPos = V3(26, 3, 6);
		lookAt = V3(0, 2, 0);
		vFov = 20.0;
		break;

	case 6:
	default:
		world = cornellBox();
		aspectRatio = 1.0;
		texWidth = 600;
		samplesPerPixel = 1000;
		maxDepth = 50;
		camPos = V3(278, 278, -800);
		lookAt = V3(278, 278, 0);
		vFov = 40.0;
		break;

	case 8:
		world = cornellSmoke();
		aspectRatio = 1.0;
		texWidth = 600;
		samplesPerPixel = 200;
		camPos = V3(278, 278, -800);
		lookAt = V3(278, 278, 0);
		vFov = 40.0;
		break;

	case 9:
		world = finalScene();
		aspectRatio = 1.0;
		texWidth = 800;
		samplesPerPixel = 10_000;
		camPos = V3(478, 278, -600);
		lookAt = V3(278, 278, 0);
		vFov = 40.0;
		break;
	}

	texHeight = cast(uint)(texWidth / aspectRatio);

	auto distanceToFocus = 10.0;
	auto cam = new Camera(camPos, lookAt, V3.up, vFov, aspectRatio, aperture, distanceToFocus, 0.0, 1.0);

	Geometry lights =
		new PlaneXZ(213, 343, 227, 332, 554, new Material());

	enum char[] spinner = ['\\', '|', '/', '-'];

	writeln;
	const invSamples = 1.0 / samplesPerPixel;
	outBuffer = new uint[](texWidth * texHeight);
	foreach (j; 0 .. texHeight)
	{
		writef!"\r %s lines remaining: %3d"(spinner[j % $], texHeight - j);
		std.stdio.stdout.flush;
		foreach (i; 0 .. texWidth)
		{
			Colour pxlColour = Colour.black;
			foreach (s; 0 .. samplesPerPixel)
			{

				const double u = cast(double)(i + uniform01) / (texWidth - 1);
				const double v = cast(
					double)(j + uniform01) / (texHeight - 1);
				Ray r = cam.ray(u, v);
				pxlColour += rayColour(r, background, world, lights, maxDepth);
			}

			outBuffer[j * texWidth + i] =
				(cast(Colour)(pxlColour * invSamples))
				.gammaCorrect
				.toUint;
		}
	}

	writeln("\ndone...");
	glGenTextures(1, &textureId);
	glBindTexture(GL_TEXTURE_2D, textureId);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(
		GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(
		GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glBindTexture(
		GL_TEXTURE_2D, 0);
	glFlush();
}

void unloadScene()
{
}

void renderScene()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glBindTexture(GL_TEXTURE_2D, textureId);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, outBuffer
			.ptr);
	glBindTexture(GL_TEXTURE_2D, 0);
	GLuint fboId;
	glGenFramebuffers(1, &fboId);
	glBindFramebuffer(GL_READ_FRAMEBUFFER, fboId);
	glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
		GL_TEXTURE_2D, textureId, 0);

	auto xDiff = (winWidth - texWidth) / 2;
	auto yDiff = (winHeight - texHeight) / 2;

	glBlitFramebuffer(0, 0, texWidth, texHeight,
		xDiff, yDiff, xDiff + texWidth, yDiff + texHeight,
		GL_COLOR_BUFFER_BIT, GL_NEAREST);
	glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
	glDeleteFramebuffers(1, &fboId);
}

int main()
{
	SDLSupport sdlStatus = loadSDL();
	if (sdlStatus != sdlSupport)
	{
		writeln("Failed loading SDL: ", sdlStatus);
		return 1;
	}

	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		throw new SDLException();

	SDLImageSupport sdlImgStatus = loadSDLImage();
	if (sdlImgStatus != sdlImageSupport)
	{
		writeln("Failed loading SDL_Image: ", sdlImgStatus);
		return 1;
	}

	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_MINOR_VERSION, 2);
	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	auto window = SDL_CreateWindow("OpenGL 3.2 App", SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED, 1024, 1024, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
	if (!window)
		throw new SDLException();
	const context = SDL_GL_CreateContext(
		window);
	if (!context)
		throw new SDLException();
	if (
		SDL_GL_SetSwapInterval(1) < 0)
		writeln("Failed to set VSync");

	GLSupport glStatus = loadOpenGL();
	if (glStatus < glSupport)
	{
		writeln("Failed loading minimum required OpenGL version: ", glStatus);
		return 1;
	}

	import std.datetime.stopwatch : benchmark;

	const time = benchmark!(loadScene)(1);
	scope (exit)
		unloadScene();
	writeln(time);

	bool quit = false;
	SDL_Event event;
	while (!quit)
	{
		while (SDL_PollEvent(&event))
		{
			switch (event.type)
			{
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym)
				{
				case SDLK_ESCAPE:
					quit = true;
					break;
				default:
					break;
				}
				break;
			case SDL_QUIT:
				quit = true;
				break;
			default:
				break;
			}
		}

		renderScene();
		SDL_GL_SwapWindow(window);
	}

	return 0;
}

Geometry[] randomWorld()
{
	Geometry[] world;

	Material matGround = new Lambertian(new Checker(Colour(0.2, 0.3, 0.1), Colour(0.9, 0.9, 0.9)));
	world ~= new Sphere(V3(0.0, -1000, 0), 1000, matGround);

	foreach (a; -6 .. 6)
	{
		foreach (b; -6 .. 6)
		{
			auto matChoice = uniform01;
			V3 center = V3(a + 0.9 * uniform01, 0.2, b + 0.9 * uniform01);

			if ((center - V3(4, 0.2, 0)).magnitude > 0.9)
			{
				Material mat;

				if (matChoice < 0.8)
				{
					auto albedo = Colour.random().hadamard(Colour.random());
					mat = new Lambertian(cast(Colour) albedo);
					auto center2 = center + V3(0, uniform(0.0, 0.5), 0);
					world ~= new MovingSphere(center, center2, 0.0, 1.0, 0.2, mat);
				}
				else if (matChoice < 0.95)
				{
					auto albedo = Colour.random(0.5, 1.0);
					auto roughness = uniform(0.0, 0.5);
					mat = new Metal(albedo, roughness);
					world ~= new Sphere(center, 0.2, mat);
				}
				else
				{
					mat = new Dielectric(1.5);
					world ~= new Sphere(center, 0.2, mat);
				}
			}
		}
	}

	auto mat1 = new Dielectric(1.5);
	world ~= new Sphere(V3(0, 1, 0), 1.0, mat1);

	auto mat2 = new Lambertian(Colour(0.4, 0.2, 0.1));
	world ~= new Sphere(V3(-4, 1, 0), 1.0, mat2);

	auto mat3 = new Metal(Colour(0.7, 0.6, 0.5), 0.0);
	world ~= new Sphere(V3(4, 1, 0), 1.0, mat3);

	return world;
}

Geometry[] twoSpheres()
{
	Geometry[] world;

	auto tex = new Checker(Colour(0.2, 0.3, 0.1), Colour(0.9, 0.9, 0.9));

	world ~= new Sphere(V3(0.0, -10, 0), 10, new Lambertian(tex));
	world ~= new Sphere(V3(0.0, 10, 0), 10, new Lambertian(tex));

	return world;
}

Geometry[] twoPerlinSpheres()
{
	Geometry[] world;

	auto tex = new Noise(4);

	world ~= new Sphere(V3(0, -1000, 0), 1000, new Lambertian(tex));
	world ~= new Sphere(V3(0, 2, 0), 2, new Lambertian(tex));

	return world;
}

Geometry[] earth()
{
	Geometry[] world;

	auto tex = new Image("public/earthmap.jpg");
	auto surf = new Lambertian(tex);
	world ~= new Sphere(V3(0, 0, 0), 2, surf);

	return world;
}

Geometry[] simpleLight()
{
	Geometry[] world;

	auto tex = new Noise(4);

	world ~= new Sphere(V3(0, -1000, 0), 1000, new Lambertian(tex));
	world ~= new Sphere(V3(0, 2, 0), 2, new Lambertian(tex));

	auto light = new DiffuseLight(Colour(4, 4, 4));
	world ~= new PlaneXY(3, 5, 1, 3, -2, light);

	return world;
}

Geometry[] cornellBox()
{
	Geometry[] world;

	auto red = new Lambertian(Colour(0.65, 0.05, 0.05));
	auto white = new Lambertian(Colour(0.73, 0.73, 0.73));
	auto green = new Lambertian(Colour(0.12, 0.45, 0.15));
	auto light = new DiffuseLight(Colour(15, 15, 15));

	world ~= new PlaneYZ(0, 555, 0, 555, 0, green);
	world ~= new PlaneYZ(0, 555, 0, 555, 555, red);
	world ~= new FlipFace(new PlaneXZ(213, 343, 227, 332, 554, light));
	world ~= new PlaneXZ(0, 555, 0, 555, 0, white);
	world ~= new PlaneXZ(0, 555, 0, 555, 555, white);
	world ~= new PlaneXY(0, 555, 0, 555, 555, white);

	Geometry box1 = new Box(V3(0, 0, 0), V3(165, 330, 165), white);
	box1 = new RotateY(box1, 15);
	box1 = new Translate(box1, V3(265, 0, 259));
	world ~= box1;

	Geometry box2 = new Box(V3(0, 0, 0), V3(165, 165, 165), white);
	box2 = new RotateY(box2, -18);
	box2 = new Translate(box2, V3(130, 0, 65));
	world ~= box2;

	return world;
}

Geometry[] cornellSmoke()
{
	Geometry[] world;

	auto red = new Lambertian(Colour(0.65, 0.05, 0.05));
	auto white = new Lambertian(Colour(0.73, 0.73, 0.73));
	auto green = new Lambertian(Colour(0.12, 0.45, 0.15));
	auto light = new DiffuseLight(Colour(15, 15, 15));

	world ~= new PlaneYZ(0, 555, 0, 555, 0, green);
	world ~= new PlaneYZ(0, 555, 0, 555, 555, red);
	world ~= new PlaneXZ(113, 443, 127, 432, 554, light);
	world ~= new PlaneXZ(0, 555, 0, 555, 0, white);
	world ~= new PlaneXZ(0, 555, 0, 555, 555, white);
	world ~= new PlaneXY(0, 555, 0, 555, 555, white);

	Geometry box1 = new Box(V3(0, 0, 0), V3(165, 330, 165), white);
	box1 = new RotateY(box1, 15);
	box1 = new Translate(box1, V3(265, 0, 259));
	world ~= new ConstantMedium(box1, 0.01, Colour.black);

	Geometry box2 = new Box(V3(0, 0, 0), V3(165, 165, 165), white);
	box2 = new RotateY(box2, -18);
	box2 = new Translate(box2, V3(130, 0, 65));
	world ~= new ConstantMedium(box2, 0.01, Colour.white);

	return world;
}

Geometry[] finalScene()
{
	Geometry[] boxes1;
	auto ground = new Lambertian(Colour(0.48, 0.83, 0.53));

	enum boxesPerSide = 20;
	foreach (i; 0 .. boxesPerSide)
	{
		foreach (j; 0 .. boxesPerSide)
		{
			enum w = 100.0;
			auto x0 = -1000.0 + i * w;
			auto z0 = -1000.0 + j * w;
			auto x1 = x0 + w;
			auto z1 = z0 + w;

			boxes1 ~= new Box(V3(x0, 0.0, z0), V3(x1, uniform(1, 101), z1), ground);
		}
	}

	Geometry[] world;

	world ~= new BVH(boxes1, 0, 1);

	auto light = new DiffuseLight(Colour(7, 7, 7));
	world ~= new PlaneXZ(123, 423, 147, 412, 554, light);

	auto center1 = V3(400, 400, 200);
	auto center2 = center1 + V3(30, 0, 0);
	auto movingSphereMat = new Lambertian(Colour(0.7, 0.3, 0.1));
	world ~= new MovingSphere(center1, center2, 0, 1, 50, movingSphereMat);

	world ~= new Sphere(V3(260, 150, 45), 50, new Dielectric(1.5));
	world ~= new Sphere(V3(0, 150, 50), 50, new Metal(Colour(0.8, 0.8, 0.9), 1.0));

	auto boundary = new Sphere(V3(360, 150, 145), 70, new Dielectric(1.5));
	world ~= boundary;
	world ~= new ConstantMedium(boundary, 0.2, Colour(0.2, 0.4, 0.9));
	boundary = new Sphere(V3.zero, 5000, new Dielectric(1.5));
	world ~= new ConstantMedium(boundary, 0.0001, Colour.white);

	auto emat = new Lambertian(new Image("public/earthmap.jpg"));
	world ~= new Sphere(V3(400, 200, 400), 100, emat);

	auto perText = new Noise(0.1);
	world ~= new Sphere(V3(220, 280, 300), 80, new Lambertian(perText));

	Geometry[] boxes2;
	auto white = new Lambertian(Colour(0.73, 0.73, 0.73));

	enum ns = 1000;
	foreach (j; 0 .. ns)
	{
		boxes2 ~= new Sphere(V3.random(0, 165), 10, white);
	}

	world ~= new Translate(new RotateY(new BVH(boxes2, 0.0, 1.0), 15), V3(-100, 270, 395));

	return world;
}

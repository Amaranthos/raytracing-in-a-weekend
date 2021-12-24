import bindbc.sdl;
import bindbc.opengl;

import std.random;
import std.stdio;
import std.string;

import camera;
import colour;
import exception;
import geometry;
import hit_record;
import material;
import ray;
import texture;
import v3;

enum double aspectRatio = 16.0 / 9.0;

enum uint texWidth = 400;
enum uint texHeight = cast(uint)(texWidth / aspectRatio);

enum uint winWidth = texWidth;
enum uint winHeight = texHeight;

enum uint samplesPerPixel = 100;
enum uint maxDepth = 50;

GLuint textureId;
uint[] outBuffer;

Colour rayColour(in Ray ray, Geometry[] world, in int depth)
{
	HitRecord rec;

	if (depth <= 0)
	{
		return Colour.black;
	}

	if (world.hit(ray, 0.001, double.infinity, rec))
	{
		Ray scattered;
		Colour attenuation;

		if (rec.mat.scatter(ray, rec, attenuation, scattered))
		{
			return cast(Colour) attenuation.hadamard(rayColour(scattered, world, depth - 1));
		}
		return Colour.black;
	}

	V3 dir = ray.dir.normalised;
	const t = 0.5 * (dir.y + 1.0);
	return cast(Colour) Colour.one.lerp(Colour(0.5, 0.7, 1.0), t);
}

void loadScene()
{
	outBuffer = new uint[](texWidth * texHeight);

	Geometry[] world;

	V3 camPos;
	V3 lookAt;
	auto vFov = 40.0;
	auto aperture = 0.0;

	switch (0)
	{
	case 1:
		world = randomWorld();
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		aperture = 0.1;
		break;

	case 2:
		world = twoSpheres();
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		break;

	case 3:
	default:
		world = twoPerlinSpheres();
		camPos = V3(13, 2, 3);
		lookAt = V3(0, 0, 0);
		vFov = 20.0;
		break;
	}

	auto distanceToFocus = 10.0;
	auto cam = new Camera(camPos, lookAt, V3.up, vFov, aspectRatio, aperture, distanceToFocus, 0.0, 1.0);

	enum char[] spinner = ['\\', '|', '/', '-'];

	writeln;
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
				pxlColour += rayColour(r, world, maxDepth);
			}

			enum invSamples = 1.0 / samplesPerPixel;

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
	glBlitFramebuffer(0, 0, texWidth, texHeight,
		0, 0, winWidth, winHeight,
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
	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_MINOR_VERSION, 2);
	SDL_GL_SetAttribute(
		SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	auto window = SDL_CreateWindow("OpenGL 3.2 App", SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED, winWidth, winHeight, SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN);
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

	auto tex = new Noise();

	world ~= new Sphere(V3(0, -1000, 0), 1000, new Lambertian(tex));
	world ~= new Sphere(V3(0, 2, 0), 2, new Lambertian(tex));

	return world;
}

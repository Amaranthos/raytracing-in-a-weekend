import bindbc.sdl;
import bindbc.opengl;

import std.random;
import std.stdio;
import std.string;

import camera;
import colour;
import exception;
import geometry;
import ray;
import v3;

enum double aspectRatio = 16.0 / 9.0;

enum uint texWidth = 400;
enum uint texHeight = cast(uint)(texWidth / aspectRatio);

enum uint winWidth = texWidth;
enum uint winHeight = texHeight;

enum uint samplesPerPixel = 100;
enum uint maxDepth = 50;

GLuint textureId;
uint[] texture;

Camera cam;
Geometry[] world;

Colour rayColour(in Ray ray, in Geometry[] world, in int depth)
{
	HitRecord rec;

	if (depth <= 0)
	{
		return Colour.black;
	}

	if (world.hit(ray, 0.001, double.infinity, rec))
	{
		V3 target = rec.pos + rec.norm + randomUnitVector;
		// V3 target = rec.pos + rec.norm + randomPointInUnitSphere;
		// V3 target = rec.pos + randomInHemisphere(rec.norm);
		return cast(Colour)(0.5 * rayColour(Ray(rec.pos, target - rec.pos), world, depth - 1));
	}

	V3 dir = ray.dir.normalised;
	const t = 0.5 * (dir.y + 1.0);
	return cast(Colour) Colour.one.lerp(Colour(0.5, 0.7, 1.0), t);
}

void loadScene()
{
	cam = new Camera();
	texture = new uint[](texWidth * texHeight);
	world ~= new Sphere(V3(0.0, -100.5, -1.0), 100);
	world ~= new Sphere(V3(0.0, 0.0, -1.0), 0.5);
	foreach (j; 0 .. texHeight)
	{
		writefln!"lines remaining: %s "(texHeight - j);
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

			texture[j * texWidth + i] =
				(cast(Colour)(pxlColour * invSamples))
				.gammaCorrect
				.toUint;
		}
	}

	writeln("done...");
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
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture
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

	loadScene();
	scope (exit)
		unloadScene();
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

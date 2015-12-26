module ex;

import std.c.stdio : fputs, fputc, stderr;
import derelict.opengl3.gl3;

extern(C) nothrow void glfwPrintError(int error, const(char)* description) {
	fputs(description, stderr);
	fputc('\n', stderr);
}

void glCheckError() {
	debug
	{
		if (glGetError() != GL_NO_ERROR) {
			throw new Exception("OpenGL encountered an error!");
		}
	}
}

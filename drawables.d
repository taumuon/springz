module drawables;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

import gl3n.math;
import gl3n.linalg;

import physics;
import ex;

import std.array;
import std.algorithm;

private GLint            vSize = 4, cSize = 3;
private GLsizei         stride = 4 * float.sizeof;

Node[] _nodes;
Spring[] _springs;
SpringSystem _springSystem;

class SurfaceDrawable
{
	private auto _nodesPerSide = 17;
	private auto _separation = 0.25;

	private GLsizei _numTriangles;

	@property GLsizei numTriangles() { return _numTriangles; }

	void Initialise(GLuint vaoEntry, GLuint[] vbo, GLuint vertexLoc, GLuint colorLoc)
	{
		glBindVertexArray(vaoEntry);

		// Generate two slots for the vertex and color buffers
		glGenBuffers(2, vbo.ptr);

		_numTriangles = (_nodesPerSide - 1) * (_nodesPerSide - 1) * 2;

		foreach(x; 0 .. _nodesPerSide)
		{
			foreach(z; 0 .. _nodesPerSide)
			{
				auto node = new Node(vec3((x * _separation), 0.0, (z * _separation)));
				_nodes ~= node;
				if (x == 0 || x == _nodesPerSide - 1 || z == 0 || z == _nodesPerSide - 1)
				{
					node.fixed = true;
				}
			}
		}

		GLfloat[] verts;
		foreach(x; 0 .. _nodesPerSide - 1)
		{
			foreach(y; 0 .. _nodesPerSide - 1)
			{
				// First triangle in square
				auto node1 = _nodes[(x * _nodesPerSide) + y];
				auto node2 = _nodes[(x * _nodesPerSide) + y + 1];
				auto node3 = _nodes[((x+1) * _nodesPerSide) + y];
				auto spring1 = CreateSpring(node1, node2);
				auto spring2 = CreateSpring(node2, node3);
				auto spring3 = CreateSpring(node3, node1);
				_springs ~= [spring1, spring2, spring3];

				// Second triangle in square
				auto node4 = _nodes[(x * _nodesPerSide) + y + 1];
				auto node5 = _nodes[((x+1) * _nodesPerSide) + y + 1];
				auto node6 = _nodes[((x+1) * _nodesPerSide) + y];
				auto spring4 = CreateSpring(node4, node5);
				auto spring5 = CreateSpring(node5, node6);
				auto spring6 = CreateSpring(node6, node4);
				_springs ~= [spring4, spring5, spring6];
			}
		}

		_springSystem = new SpringSystem(_springs);

		auto vertLength = BindVertData(vbo);
		glEnableVertexAttribArray(vertexLoc);
		glVertexAttribPointer(vertexLoc, vSize, GL_FLOAT, GL_FALSE, stride, null);
		glCheckError();

		// bind buffer for colors and copy data into buffer
		BindColourData(vbo);
		glEnableVertexAttribArray(colorLoc);
		glVertexAttribPointer(colorLoc, cSize, GL_FLOAT, GL_FALSE, stride, null);
		glCheckError();
	}

	private Spring CreateSpring(Node node1, Node node2)
	{
		return new Spring(node1, node2, (node2.position - node1.position).length);
	}

	private int BindVertData(GLuint[] vbo)
	{
		auto allNodes = map!(spring => [spring.node1, spring.node2])(_springs).joiner();
		auto vertArrays = map!(node => [node.position.x, node.position.y, node.position.z, 1.0f])(allNodes);
		GLfloat[] verts = joiner(vertArrays).array();

		// bind buffer for vertices and copy data into buffer
		glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
		glBufferData(GL_ARRAY_BUFFER, verts.length * GLfloat.sizeof, verts.ptr, GL_STATIC_DRAW);

		return verts.length;
	}

	private void BindColourData(GLuint[] vbo)
	{
		GLfloat[] colours;
		auto factor = 5.0;
		foreach(spring; _springs)
		{
			auto strain = spring.strain;
			auto color = min(1.0, strain * factor);

			// Set twice, as both nodes in the spring are the same colour
			colours ~= [color, 1.0 - color, 0.0, 1.0];
			colours ~= [color, 1.0 - color, 0.0, 1.0];
		}

		glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
		glBufferData(GL_ARRAY_BUFFER, colours.length * GLfloat.sizeof, colours.ptr, GL_STATIC_DRAW);
		glCheckError();
	}

	void Update(GLuint[] vbo)
	{
		auto deltaT = 0.01;
		foreach(_; 0 .. 4)
		{
			_springSystem.Update(deltaT);
		}

		BindVertData(vbo);
		BindColourData(vbo);
	}
}

class Axes
{
	enum axisLength = 1.0;

	// Data for drawing Axis
	GLfloat[] verticesAxis = [
		-axisLength,  0.0,  0.0f, 1.0,
		axisLength,  0.0,  0.0f, 1.0,
		0.0,-axisLength,  0.0f, 1.0,
		0.0, axisLength,  0.0f, 1.0,
		0.0,  0.0,-axisLength, 1.0,
		0.0,  0.0, axisLength, 1.0];

	GLfloat[] colorAxis = [
		1.0, 0.0, 0.0, 1.0,
		1.0, 0.0, 0.0, 1.0,
		0.0, 1.0, 0.0, 1.0,
		0.0, 1.0, 0.0, 1.0,
		0.0, 0.0, 1.0, 1.0,
		0.0, 0.0, 1.0, 1.0];

	void Initialise(GLuint vaoEntry, GLuint[] vbo, GLuint vertexLoc, GLuint colorLoc)
	{
		//////////////////////////////////////////////////////////////////////////////
		// VAO for the Axis
		glBindVertexArray(vaoEntry);

		// Generate two slots for the vertex and color buffers
		glGenBuffers(2, vbo.ptr);

		// bind buffer for vertices and copy data into buffer
		glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
		glBufferData(GL_ARRAY_BUFFER, verticesAxis.length * GLfloat.sizeof, verticesAxis.ptr, GL_STATIC_DRAW);
		glEnableVertexAttribArray(vertexLoc);
		glVertexAttribPointer(vertexLoc, vSize, GL_FLOAT, GL_FALSE, stride, null);

		// bind buffer for colors and copy data into buffer
		glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
		glBufferData(GL_ARRAY_BUFFER, colorAxis.length * GLfloat.sizeof, colorAxis.ptr, GL_STATIC_DRAW);
		glEnableVertexAttribArray(colorLoc);
		glVertexAttribPointer(colorLoc, cSize, GL_FLOAT, GL_FALSE, stride, null);
		glCheckError();
	}
}
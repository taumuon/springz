module physics;

import gl3n.math;
import gl3n.linalg;

class Node
{
	private vec3 _position;
	private vec3 _velocity;
	private vec3 _acceleration;

	private bool _fixed;

	this(vec3 position)
	{
		_position = position;
		_velocity = vec3(0.0);
		_acceleration = vec3(0.0);

		_fixed = false;
	}

	@property vec3 position() { return _position; }
	@property vec3 position(vec3 value) { return _position = value; }

	@property vec3 acceleration() { return _acceleration; }
	@property vec3 acceleration(vec3 value) { return _acceleration = value; }

	@property fixed() { return _fixed; }
	@property fixed(bool value) { _fixed = value; }

	// enum damping = 0.00001;
	enum damping = 0.0;
	
	public void Update(double deltaT)
	{
		_acceleration -= _velocity.normalized() * damping;
	
		_velocity += _acceleration * deltaT;
		_position += _velocity * deltaT;
	}
}

class Spring
{
	private Node _node1;
	private Node _node2;
	private float _restLength;

	this(Node node1, Node node2, float restLength)
	{
		_node1 = node1;
		_node2 = node2;
		_restLength = restLength;
	}

	@property Node node1() { return _node1; }
	@property Node node2() { return _node2; }

	@property float strain()
	{
		auto length = (_node2.position - _node1.position).length;
		auto extension = length - _restLength;
		return extension / _restLength;
	}
}

class SpringSystem
{
	private Spring[] _springs;

	this(Spring[] springs)
	{
		_springs = springs;
	}

	@property Spring[] springs() { return _springs; }

	private auto stiffness = 0.005f;

	void Update(float deltaT)
	{
		vec3[Node] accumulatedForces;
		foreach(spring; _springs)
		{
			auto node1 = spring.node1;
			auto node2 = spring.node2;

			auto forceDirection = (node2.position - node1.position).normalized();
			auto force = forceDirection * spring.strain * stiffness;

			accumulatedForces[node1] = (node1 in accumulatedForces) ? accumulatedForces[node1] + force : force;
			accumulatedForces[node2] = (node2 in accumulatedForces) ? accumulatedForces[node2] - force : -force;
		}

		auto gravity = vec3(0.0, -0.0001, 0.0);
		foreach(nodeItem; accumulatedForces.byKeyValue())
		{
			nodeItem.key.acceleration = nodeItem.key.fixed ? vec3(0.0) : nodeItem.value + gravity;
		}

		foreach(spring; _springs)
		{
			spring.node1.Update(deltaT);
			spring.node2.Update(deltaT);
		}
	}
}

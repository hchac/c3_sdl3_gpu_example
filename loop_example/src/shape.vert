#version 460

layout (location = 0) in vec3 in_position;
layout (location = 1) in vec3 in_color;
layout (location = 2) in vec2 in_uv;

layout (set = 1, binding = 0) uniform VertexTransform
{
	mat4 mvp;
};

layout (location = 0) out vec4 our_color;
layout (location = 1) out vec2 uv;

void main()
{
	gl_Position = mvp * vec4(in_position, 1.0);
	our_color = vec4(in_color, 1.0);
	uv = in_uv;
}

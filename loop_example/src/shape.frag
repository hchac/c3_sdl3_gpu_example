#version 460

layout (location = 0) in vec4 our_color;
layout (location = 1) in vec2 uv;

layout (set = 2, binding = 0) uniform sampler2D tex_sampler0;
layout (set = 2, binding = 1) uniform sampler2D tex_sampler1;

layout (location = 0) out vec4 FragColor;

void main()
{
	// FragColor = texture(tex_sampler0, uv) * our_color;
	// FragColor = texture(tex_sampler0, uv);

	FragColor = mix(
		texture(tex_sampler0, uv),
		texture(tex_sampler1, uv),
		0.2
	) * our_color;
}

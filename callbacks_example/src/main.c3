module callback_example;

import std::io;
import std::math;
import std::math::matrix;

import sdl3;
import sdl3_image;

SdlWindow* window;
SdlGPUDevice* gpu;
SdlGPUGraphicsPipeline* pipeline;
SdlGPUBuffer* vertex_buffer;
SdlGPUBuffer* index_buffer;
SdlGPUTexture* texture;
SdlGPUSampler* sampler;

char[*] vert_shader_code = $embed("../build/shader.spv.vert");
char[*] frag_shader_code = $embed("../build/shader.spv.frag");

struct Ubo
{
	Mat4 mvp;
}

struct VertexData
{
	Vec3 pos;
	SdlFColor color;
	float[2] uv;
}

float rotation;
float last_tick;

fn SdlAppResult init(void** state, CInt argc, char** argv) @export("SDL_AppInit")
{
	SdlSurface* png_image = load_image("./resources/cobblestone_1.png")!!;

	sdl3::setLogPriorities(VERBOSE);
	sdl3::setLogOutputFunction(fn(void* userdata, SdlLogCategory category, SdlLogPriority priority, ZString message) {
		io::printfn("[%s] %s: %s", priority, category, message);
	}, null);

	if (!sdl3::init({ .video = true }))
	{
		sdl_error("failed to init sdl3");
		return FAILURE;
	}

	window = sdl3::createWindow("callback_example", 1280, 720, { .resizable = true });
	if (!window)
	{
		sdl_error("failed to create window");
		return FAILURE;
	}

	gpu = sdl3::createGPUDevice({ .spirv = true }, true, null);
	if (!gpu)
	{
		sdl_error("failed to create gpu device");
		return FAILURE;
	}

	if (!sdl3::claimWindowForGPUDevice(gpu, window))
	{
		sdl_error("failed to claim window for gpu device");
		return FAILURE;
	}

	SdlGPUShader* vert_shader = load_shader(gpu, &vert_shader_code, VERTEX, 1, 0);
	defer sdl3::releaseGPUShader(gpu, vert_shader);
	SdlGPUShader* frag_shader = load_shader(gpu, &frag_shader_code, FRAGMENT, 0, 1);
	defer sdl3::releaseGPUShader(gpu, frag_shader);

	VertexData[*] vertices = {
		{ {	-0.5,  0.5, 0 }, { 1, 0, 0, 1 }, { 0, 0 } }, // top left
		{ {	-0.5, -0.5, 0 }, { 0, 1, 0, 1 }, { 0, 1 } }, // bottom left
		{ {	 0.5, -0.5, 0 }, { 0, 0, 1, 1 }, { 1, 1 } }, // bottom right
		{ {	 0.5,  0.5, 0 }, { 1, 1, 0, 1 }, { 1, 0 } }, // top right
	};

	vertex_buffer = sdl3::createGPUBuffer(gpu, &&{
		.usage = { .vertex = true },
		.size = $reflect(vertices).size,
	});

	ushort[*] indices = {
		0, 1, 2,
		0, 2, 3,
	};

	index_buffer = sdl3::createGPUBuffer(gpu, &&{
		.usage = { .index = true },
		.size = $reflect(indices).size,
	});

	copy_to_gpu_buffer(
		gpu,
		{vertex_buffer, &vertices, $reflect(vertices).size},
		{index_buffer, &indices, $reflect(indices).size},
	)!!;

	texture = sdl3::createGPUTexture(gpu, &&{
		.type = T2D,
		.format = R8G8B8A8_UNORM,
		.usage = { .sampler = true },
		.width = png_image.w,
		.height = png_image.h,
		.layer_count_or_depth = 1,
		.num_levels = 1,
	});

	copy_to_gpu_texture(
		gpu,
		{texture, png_image.pixels, png_image.h*png_image.pitch, png_image.w, png_image.h},
	)!!;

	SdlGPUVertexBufferDescription[*] vertex_buff_descs = {
		{
			.slot = 0,
			.pitch = VertexData::size,
		},
	};

	SdlGPUVertexAttribute[*] vertex_attrs = {
		{
			.location = 0,
			.format = FLOAT3,
			.offset = $reflect(VertexData.pos).offset,
		},
		{
			.location = 1,
			.format = FLOAT4,
			.offset = $reflect(VertexData.color).offset,
		},
		{
			.location = 2,
			.format = FLOAT2,
			.offset = $reflect(VertexData.uv).offset,
		},
	};

	sampler = sdl3::createGPUSampler(gpu, &&{});

	pipeline = sdl3::createGPUGraphicsPipeline(gpu, &&{
		.vertex_shader = vert_shader,
		.fragment_shader = frag_shader,
		.primitive_type = TRIANGLELIST,
		.vertex_input_state = {
			.vertex_buffer_descriptions = &vertex_buff_descs,
			.num_vertex_buffers = vertex_buff_descs.len,

			.vertex_attributes = &vertex_attrs,
			.num_vertex_attributes = vertex_attrs.len,
		},
		.target_info = {
			.color_target_descriptions = &&{
				.format = sdl3::getGPUSwapchainTextureFormat(gpu, window),
			},
			.num_color_targets = 1,
		},
	});
	if (!pipeline)
	{
		sdl_error("failed to create gpu graphics pipeline");
		return FAILURE;
	}

	last_tick = sdl3::getTicks();

	return CONTINUE;
}

fn SdlAppResult event(void* state, SdlEvent* event) @export("SDL_AppEvent")
{
	if (event.is_quit() || event.is_key_down(KEY_ESCAPE))
	{
		return SUCCESS;
	}

	return CONTINUE;
}

fn SdlAppResult iter(void* state) @export("SDL_AppIterate")
{
	SdlGPUCommandBuffer* command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
	if (!command_buffer)
	{
		sdl_error("failed to acquire draw command buffer");
		return FAILURE;
	}

	SdlGPUTexture* swapchain_texture;
	if (!sdl3::waitAndAcquireGPUSwapchainTexture(command_buffer, window, &swapchain_texture, null, null))
	{
		sdl_error("failed to acquire swapchain texture");
		return FAILURE;
	}

	// swapchain_texture can be null if window is minimized (not an error)
	if (swapchain_texture)
	{
		Ubo ubo;
		{
			int win_width;
			int win_height;
			sdl3::getWindowSize(window, &win_width, &win_height);
			float aspect = (float)win_width/win_height;

			float now_tick = sdl3::getTicks();
			{
				rotation += (float)math::deg_to_rad(90 * (now_tick-last_tick)/1000) % math::PI;
			}
			last_tick = now_tick;

			ubo.mvp = matrix::perspective((float)math::deg_to_rad(70), aspect, 0.0001, 1000)
					  .translate({ 0, 0, -1.2 })
					  .rotate_y(rotation);
		}

		SdlGPUColorTargetInfo*[1] color_target = {
			&&{
				.texture = swapchain_texture,
				.load_op = CLEAR,
				.clear_color = {0.5, 0.5, 0.5, 1},
				.store_op = STORE,
			},
		};
		SdlGPURenderPass* render_pass = sdl3::beginGPURenderPass(command_buffer, color_target[0], color_target.len, null);
		{
			sdl3::bindGPUGraphicsPipeline(render_pass, pipeline);

			SdlGPUBufferBinding[*] vertex_buffers_bindings = {
				{
					.buffer = vertex_buffer,
					.offset = 0,
				},
			};
			sdl3::bindGPUVertexBuffers(render_pass, 0, &vertex_buffers_bindings, vertex_buffers_bindings.len);
			sdl3::bindGPUIndexBuffer(render_pass, &&{ .buffer = index_buffer }, BIT16);
			sdl3::pushGPUVertexUniformData(command_buffer, 0, &ubo, $reflect(ubo).size);

			SdlGPUTextureSamplerBinding[*] texture_bindings = {
				{
					.texture = texture,
					.sampler = sampler,
				},
			};
			sdl3::bindGPUFragmentSamplers(render_pass, 0, &texture_bindings, texture_bindings.len);

			sdl3::drawGPUIndexedPrimitives(render_pass, 6, 1, 0, 0, 0);
		}
		sdl3::endGPURenderPass(render_pass);
	}

	if (!sdl3::submitGPUCommandBuffer(command_buffer))
	{
		sdl_error("failed to submit draw command buffer");
		return FAILURE;
	}

	return CONTINUE;
}

fn void quit(void* state, SdlAppResult result) @export("SDL_AppQuit")
{
	if (sampler) sdl3::releaseGPUSampler(gpu, sampler);
	if (texture) sdl3::releaseGPUTexture(gpu, texture);
	if (vertex_buffer) sdl3::releaseGPUBuffer(gpu, vertex_buffer);
	if (index_buffer) sdl3::releaseGPUBuffer(gpu, index_buffer);
	if (pipeline) sdl3::releaseGPUGraphicsPipeline(gpu, pipeline);
	if (gpu) sdl3::destroyGPUDevice(gpu);
	if (window) sdl3::destroyWindow(window);
}

///////////////////////////////////////////////////////////////////////////////

faultdef LOAD_IMAGE_FAILED, GPU_BUFFER_COPY_FAILED, GPU_TEXTURE_COPY_FAILED;

fn SdlSurface*? load_image(char* path)
{
	SdlSurface* img = sdl3_image::load(path);
	if (!img)
	{
		sdl_error("failed to load image");
		return LOAD_IMAGE_FAILED~;
	}

	return img;
}

fn SdlGPUShader* load_shader(SdlGPUDevice* device, char[] code, SdlGPUShaderStage stage, uint num_uniform_buffers, uint num_samplers)
{
	return sdl3::createGPUShader(device, &&{
		.code_size = code.len,
		.code = code,
		.entrypoint = "main",
		.format = { .spirv = true },
		.stage = stage,

		.num_uniform_buffers = num_uniform_buffers,
		.num_samplers = num_samplers,
	});
}

struct GPUBufferCopyDescription
{
	SdlGPUBuffer* dest_buffer;
	void* data;
	int data_size;
}

fn void? copy_to_gpu_buffer(SdlGPUDevice* device, GPUBufferCopyDescription ...descriptions)
{
	int total_size;
	foreach (d : descriptions)
	{
		total_size += d.data_size;
	}

	SdlGPUTransferBuffer* transfer_buffer = sdl3::createGPUTransferBuffer(gpu, &&{
		.usage = UPLOAD,
		.size = total_size,
	});
	defer sdl3::releaseGPUTransferBuffer(gpu, transfer_buffer);

	void* transfer_mem = sdl3::mapGPUTransferBuffer(gpu, transfer_buffer, false);
	defer sdl3::unmapGPUTransferBuffer(gpu, transfer_buffer);

	int offset;
	foreach (d : descriptions)
	{
		mem::copy(transfer_mem[offset:d.data_size], d.data, d.data_size);
		offset += d.data_size;
	}

	SdlGPUCommandBuffer* copy_command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
	{
		SdlGPUCopyPass* copy_pass = sdl3::beginGPUCopyPass(copy_command_buffer);
		defer sdl3::endGPUCopyPass(copy_pass);

		offset = 0;
		foreach (d : descriptions)
		{
			sdl3::uploadToGPUBuffer(
				copy_pass,
				&&{
					.transfer_buffer = transfer_buffer,
					.offset = offset,
				}, 
				&&{
					.buffer = d.dest_buffer,
					.offset = 0,
					.size = d.data_size,
				},
				false,
			);
			offset += d.data_size;
		}
	}
	if (!sdl3::submitGPUCommandBuffer(copy_command_buffer))
	{
		sdl_error("failed to submit command buffer for copying to gpu buffer");
		return GPU_BUFFER_COPY_FAILED~;
	}
}

struct GPUTextureCopyDescription
{
	SdlGPUTexture* dest_texture;
	void* data;
	int data_size;
	int width;
	int height;
}

fn void? copy_to_gpu_texture(SdlGPUDevice* device, GPUTextureCopyDescription ...descriptions)
{
	int total_size;
	foreach (d : descriptions)
	{
		total_size += d.data_size;
	}

	SdlGPUTransferBuffer* transfer_buffer = sdl3::createGPUTransferBuffer(gpu, &&{
		.usage = UPLOAD,
		.size = total_size,
	});
	defer sdl3::releaseGPUTransferBuffer(gpu, transfer_buffer);

	void* transfer_mem = sdl3::mapGPUTransferBuffer(gpu, transfer_buffer, false);
	defer sdl3::unmapGPUTransferBuffer(gpu, transfer_buffer);

	int offset;
	foreach (d : descriptions)
	{
		mem::copy(transfer_mem[offset:d.data_size], d.data, d.data_size);
		offset += d.data_size;
	}

	SdlGPUCommandBuffer* copy_command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
	{
		SdlGPUCopyPass* copy_pass = sdl3::beginGPUCopyPass(copy_command_buffer);
		defer sdl3::endGPUCopyPass(copy_pass);

		offset = 0;
		foreach (d : descriptions)
		{
			sdl3::uploadToGPUTexture(
				copy_pass,
				&&{
					.transfer_buffer = transfer_buffer,
					.offset = offset,
				}, 
				&&{
					.texture = d.dest_texture,
					.w = d.width,
					.h = d.height,
					.d = 1,
				},
				false,
			);
			offset += d.data_size;
		}
	}
	if (!sdl3::submitGPUCommandBuffer(copy_command_buffer))
	{
		sdl_error("failed to submit command buffer for copying to gpu texture");
		return GPU_TEXTURE_COPY_FAILED~;
	}
}

fn void sdl_error(String message)
{
	ZString err = (ZString)sdl3::getError();
	if (err.len() > 0)
	{
		io::printfn("%s: %s", message, (ZString)err);
	}
	else
	{
		io::printfn("%s", message);
	}
}

///////////////////////////////////////////////////////////////////////////////

fn bool SdlEvent.is_quit(&self)
{
	return self.type == QUIT;
}

fn bool SdlEvent.is_key_down(&self, SdlKeycode k)
{
	if (self.type != KEY_DOWN) return false;
	SdlKeyboardEvent* kev = (SdlKeyboardEvent*)self;
	return kev.key == k;
}

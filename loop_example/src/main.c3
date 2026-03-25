module loop_example;

import std::io;
import std::math;

import sdl3;
import sdl3_image;

const MAT4I = matrix::IDENTITY4{float};
const SdlGPUTextureFormat DEPTH_TEXTURE_FORMAT = D32_FLOAT_S8_UINT;

char[*] vert_shader_code = $embed("../build/shape.spv.vert");
char[*] frag_shader_code = $embed("../build/shape.spv.frag");

char[*] container_image_source = $embed("../resources/container.png");
char[*] awesomeface_source = $embed("../resources/awesomeface.png");

fn int main(String[] args)
{
	sdl3::setLogPriorities(VERBOSE);
	sdl3::setLogOutputFunction(fn(void* userdata, SdlLogCategory category, SdlLogPriority priority, ZString message) {
		io::printfn("[%s] %s: %s", priority, category, message);
	}, null);

	if (!sdl3::init({ .video = true }))
	{
		sdl_error("failed to init sdl");
		return -1;
	}
	defer sdl3::quit();

	SdlWindow* window = sdl3::createWindow("loop_example", 800, 600, { .resizable = true, .opengl = true });
	if (!window)
	{
		sdl_error("failed to create window");
		return -1;
	}
	defer sdl3::destroyWindow(window);

	SdlGPUDevice* gpu = sdl3::createGPUDevice({ .spirv = true }, true, null);
	if (!gpu)
	{
		sdl_error("failed to create gpu device");
		return -1;
	}
	defer sdl3::destroyGPUDevice(gpu);

	if (!sdl3::claimWindowForGPUDevice(gpu, window))
	{
		sdl_error("failed to claim window for gpu device");
		return -1;
	}

	SdlGPUTexture* container_texture = load_texture(gpu, &container_image_source)!!;
	defer sdl3::releaseGPUTexture(gpu, container_texture);
	SdlGPUTexture* awesomeface_texture = load_texture(gpu, &awesomeface_source)!!;
	defer sdl3::releaseGPUTexture(gpu, awesomeface_texture);

	SdlGPUSampler* sampler = sdl3::createGPUSampler(
		gpu, 
		&&{},
	);
	defer sdl3::releaseGPUSampler(gpu, sampler);

	VertexData[*] vertices = {
		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ {  0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ {  0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ {  0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ { -0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },

		{ { -0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ {  0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ { -0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ { -0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },

		{ { -0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ { -0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ { -0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ { -0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },

		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ {  0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ {  0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ {  0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ {  0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },

		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ {  0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ {  0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ {  0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ { -0.5, -0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ { -0.5, -0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },

		{ { -0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
		{ {  0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 1.0 } },
		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ {  0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 1.0, 0.0 } },
		{ { -0.5,  0.5,  0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 0.0 } },
		{ { -0.5,  0.5, -0.5 }, { 1.0, 1.0, 1.0 }, { 0.0, 1.0 } },
	};

	SdlGPUBuffer* vertex_buffer = sdl3::createGPUBuffer(gpu, &&{
		.usage = { .vertex = true },
		.size = $sizeof(vertices),
	});
	defer sdl3::releaseGPUBuffer(gpu, vertex_buffer);

	copy_to_gpu_buffer(
		gpu,
		{vertex_buffer, &vertices, $sizeof(vertices)},
	)!!;

	SdlGPUShader* vert_shader = sdl3::createGPUShader(
		gpu,
		&&{
			.code_size = vert_shader_code.len,
			.code = &vert_shader_code,
			.entrypoint = "main",
			.format = { .spirv = true },
			.stage = VERTEX,

			.num_uniform_buffers = 1,
		},
	);
	defer sdl3::releaseGPUShader(gpu, vert_shader);

	SdlGPUShader* frag_shader = sdl3::createGPUShader(
		gpu,
		&&{
			.code_size = frag_shader_code.len,
			.code = &frag_shader_code,
			.entrypoint = "main",
			.format = { .spirv = true },
			.stage = FRAGMENT,

			.num_samplers = 2,
		},
	);
	defer sdl3::releaseGPUShader(gpu, frag_shader);

	SdlGPUVertexBufferDescription[*] vertex_descriptions = {
		{
			.slot = 0,
			.pitch = VertexData.sizeof,
		},
	};

	SdlGPUVertexAttribute[*] vertex_attributes = {
		{
			.location = 0,
			.format = FLOAT3,
			.offset = VertexData.position.offsetof,
		},
		{
			.location = 1,
			.format = FLOAT3,
			.offset = VertexData.color.offsetof,
		},
		{
			.location = 2,
			.format = FLOAT2,
			.offset = VertexData.uv.offsetof,
		},
	};

	SdlGPUColorTargetDescription[*] color_target_descriptions = {
		{
			.format = sdl3::getGPUSwapchainTextureFormat(gpu, window),
		}
	};

	SdlGPUGraphicsPipeline* pipeline = sdl3::createGPUGraphicsPipeline(
		gpu,
		&&{
			.vertex_shader = vert_shader,
			.fragment_shader = frag_shader,
			.vertex_input_state = {
				.vertex_buffer_descriptions = &vertex_descriptions,
				.num_vertex_buffers = vertex_descriptions.len,
				.vertex_attributes = &vertex_attributes,
				.num_vertex_attributes = vertex_attributes.len,
			},
			.primitive_type = TRIANGLELIST,
			.target_info = {
				.color_target_descriptions = &color_target_descriptions,
				.num_color_targets = color_target_descriptions.len,

				.depth_stencil_format = DEPTH_TEXTURE_FORMAT,
				.has_depth_stencil_target = true,
			},
			.rasterizer_state = {
				// .fill_mode = LINE,
			},
			.depth_stencil_state = {
				.compare_op = LESS,
				.enable_depth_test = true,
				.enable_depth_write = true,
			},
		},
	);
	if (!pipeline)
	{
		sdl_error("failed to create gpu graphics pipeline");
		return -1;
	}
	defer sdl3::releaseGPUGraphicsPipeline(gpu, pipeline);

	defer if (depth_texture_info.texture) { sdl3::releaseGPUTexture(gpu, depth_texture_info.texture); }

	float last_tick = ticks_s();
	float dt;
	float camera_speed = 10.0;

	Camera camera = { {  0.0,  0.0,  3.0 }, 0, 0 };
	KeyboardState keyboard;
	MouseState mouse;

	bool running = true;
	while (running)
	{
		int window_width, window_height;
		if (!sdl3::getWindowSize(window, &window_width, &window_height))
		{
			sdl_error("failed to get window size");
			return -1;
		}

		{
			mouse.reset();

			SdlEvent event;
			while (sdl3::pollEvent(&event))
			{
				if (event.type == QUIT) running = false;
				keyboard.process_event(&event);
				mouse.process_event(&event);
			}
		}

		if (keyboard.is_key_down(ESCAPE)) running = false;
		if (keyboard.is_key_down(W))      camera.move((Vec3){ 0, 0, -camera_speed }*dt);
		if (keyboard.is_key_down(S))      camera.move((Vec3){ 0, 0,  camera_speed }*dt);
		if (keyboard.is_key_down(A))      camera.move((Vec3){ -camera_speed, 0, 0 }*dt);
		if (keyboard.is_key_down(D))      camera.move((Vec3){  camera_speed, 0, 0 }*dt);
		if (keyboard.is_key_down(LEFT))   camera.rotate_leftright(100*dt);
		if (keyboard.is_key_down(RIGHT))  camera.rotate_leftright(-100*dt);
		if (keyboard.is_key_down(UP))     camera.rotate_updown(100*dt);
		if (keyboard.is_key_down(DOWN))   camera.rotate_updown(-100*dt);
		if (keyboard.is_key_down(R))
		{
			camera.pos = { 0, 0, 3 };
			camera.yaw = 0;
			camera.pitch = 0;
		}

		if (mouse.right_pressed || mouse.right_down)
		{
			if (mouse.right_pressed)
			{
				mouse.lock_to_window(window, true);
			}

			camera.rotate_leftright(-mouse.delta_x*0.1f);
			camera.rotate_updown(-mouse.delta_y*0.1f);
		}
		else if (mouse.right_released)
		{
			mouse.release_from_window(window);
		}

		SdlGPUCommandBuffer* command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
		if (!command_buffer)
		{
			sdl_error("failed to acquire command buffer");
			return -1;
		}

		SdlGPUTexture* swapchain_texture;
		if (!sdl3::waitAndAcquireGPUSwapchainTexture(command_buffer, window, &swapchain_texture, null, null))
		{
			sdl_error("failed to acquire swapchain texture");
			return -1;
		}
		if (swapchain_texture)
		{
			SdlGPUColorTargetInfo[*] color_target_infos = {
				{
					.texture = swapchain_texture,
					.clear_color = { 0.2, 0.3, 0.3, 1.0 },
					.load_op = CLEAR,
				}
			};
			update_depth_stencil_texture(gpu, &depth_texture_info, window_width, window_height)!!;
			SdlGPUDepthStencilTargetInfo depth_target = {
				.texture = depth_texture_info.texture,
				.clear_depth = 1.0,
				.load_op = CLEAR,
				.store_op = DONT_CARE,
				.stencil_load_op = DONT_CARE,
				.stencil_store_op = DONT_CARE,
				// .cycle = true,
			};
			SdlGPURenderPass* render_pass = sdl3::beginGPURenderPass(
				command_buffer,
				&color_target_infos,
				color_target_infos.len,
				&depth_target,
			);
			defer sdl3::endGPURenderPass(render_pass);

			sdl3::bindGPUGraphicsPipeline(render_pass, pipeline);

			SdlGPUBufferBinding[*] buffer_bindings = {
				{ .buffer = vertex_buffer },
			};
			sdl3::bindGPUVertexBuffers(render_pass, 0, &buffer_bindings, buffer_bindings.len);

			SdlGPUTextureSamplerBinding[*] sampler_bindings = {
				{
					.texture = container_texture,
					.sampler = sampler,
				},
				{
					.texture = awesomeface_texture,
					.sampler = sampler,
				},
			};
			sdl3::bindGPUFragmentSamplers(render_pass, 0, &sampler_bindings, sampler_bindings.len);

			float[3][*] cube_positions = {
				{  0.0,  0.0,  0.0  },
				{  2.0,  5.0, -15.0 },
				{ -1.5, -2.2, -2.5  },
				{ -3.8, -2.0, -12.3 },
				{  2.4, -0.4, -3.5  },
				{ -1.7,  3.0, -7.5  },
				{  1.3, -2.0, -2.5  },
				{  1.5,  2.0, -2.5  },
				{  1.5,  0.2, -1.5  },
				{ -1.3,  1.0, -1.5  },
			};
			{
				Mat4 model_matrix = MAT4I
					.rotate((float)(sdl3::getTicks() / 1000.0) * to_rad(55), { 0.5, 1.0, 0.0 })
				;
				Mat4 camera_view = camera.view();
				Mat4 projection_matrix = matrix::perspective(to_rad(45), (float)window_width/window_height, 0.1, 100);

				foreach (pos : cube_positions)
				{
					Mat4 view_matrix = camera_view
						.translate(pos)
					;

					VertexTransform vertex_transform = {
						projection_matrix*view_matrix*model_matrix,
					};
					sdl3::pushGPUVertexUniformData(
						command_buffer, 0, &vertex_transform, $sizeof(vertex_transform),
					);

					sdl3::drawGPUPrimitives(render_pass, vertices.len, 1, 0, 0);
				}
			}
		}

		if (!sdl3::submitGPUCommandBuffer(command_buffer))
		{
			sdl_error("failed to submit command buffer");
			return -1;
		}

		float now = ticks_s();
		dt = now-last_tick;
		last_tick = now;
	}

	return 0;
}

struct DepthStencilTextureInfo
{
	SdlGPUTexture* texture;
	int current_width, current_height;
}

DepthStencilTextureInfo depth_texture_info;

struct VertexData
{
	Vec3 position;
	Vec3 color;
	Vec2 uv;
}

struct VertexTransform
{
	Mat4 mvp;
}


///////////////////////////////////////////////////////////////////////////////


struct Camera
{
	Vec3 pos;
	float yaw, pitch;
}

fn Vec3 Camera.facing(self)
{
	Vec3 facing;
	facing.x = math::cos(to_rad(90+self.yaw)) * math::cos(to_rad(self.pitch));
	facing.z = -math::sin(to_rad(90+self.yaw)) * math::cos(to_rad(self.pitch));
	facing.y = math::sin(to_rad(self.pitch));

	return facing;
}

fn Mat4 Camera.view(self, Vec3 up = { 0, 1, 0 })
{
	return matrix::look_at(self.pos, self.pos+self.facing(), up);
}

fn void Camera.move(&self, Vec3 amount)
{
	self.pos += amount.transform(self.view());
}

fn void Camera.rotate_leftright(&self, float angle_degrees)
{
	self.yaw = (360 + ((self.yaw+angle_degrees) % 360)) % 360;
}

fn void Camera.rotate_updown(&self, float angle_degrees)
{
	self.pitch = math::clamp(self.pitch+angle_degrees, -89.99f, 89.99f);
}

///////////////////////////////////////////////////////////////////////////////


struct KeyboardState
{
	bool[(uint)SdlScancode.COUNT] key_down;
}
fn void KeyboardState.process_event(&self, SdlEvent* ev)
{
	if (ev.type != KEY_DOWN && ev.type != KEY_UP) return;
	SdlKeyboardEvent* kev = (SdlKeyboardEvent*)ev;
	self.key_down[(uint)kev.scancode] = ev.type == KEY_DOWN;
}

fn bool KeyboardState.is_key_down(&self, SdlScancode k) => (uint)k < self.key_down.len && self.key_down[(uint)k];

struct MouseState
{
	bool left_down, left_pressed, left_released;
	bool right_down, right_pressed, right_released;

	float x, delta_x;
	float y, delta_y;
}

fn void MouseState.reset(&self)
{
	self.left_pressed = false;
	self.left_released = false;
	self.right_pressed = false;
	self.right_released = false;

	self.delta_x = 0;
	self.delta_y = 0;
}

fn void MouseState.process_event(&self, SdlEvent* ev)
{
	if (ev.type == MOUSE_BUTTON_DOWN || ev.type == MOUSE_BUTTON_UP)
	{
		SdlMouseButtonEvent* mev = (SdlMouseButtonEvent*)ev;
		if (mev.button == (char)SdlMouseButtonFlags.LEFT)
		{
			self.left_pressed  = ev.type == MOUSE_BUTTON_DOWN;
			self.left_released = !self.left_pressed;
			self.left_down     = ev.type == MOUSE_BUTTON_DOWN;
		}
		else if (mev.button == (char)SdlMouseButtonFlags.RIGHT)
		{
			self.right_pressed  = ev.type == MOUSE_BUTTON_DOWN;
			self.right_released = !self.right_pressed;
			self.right_down     = ev.type == MOUSE_BUTTON_DOWN;
		}
	}
	else if (ev.type == MOUSE_MOTION)
	{
		SdlMouseMotionEvent* mev = (SdlMouseMotionEvent*)ev;
		self.x = mev.x;
		self.y = mev.y;
		self.delta_x = mev.xrel;
		self.delta_y = mev.yrel;
	}
}

fn void MouseState.lock_to_window(&self, SdlWindow* window, bool confine = false)
{
	sdl3::setWindowRelativeMouseMode(window, true);
	if (confine && !sdl3::setWindowMouseRect(window, &&{ (int)self.x, (int)self.y, 1, 1 }))
	{
		sdl_error("failed to confine mouse");
	}
}

fn void MouseState.release_from_window(&self, SdlWindow* window)
{
	sdl3::setWindowRelativeMouseMode(window, false);
	sdl3::setWindowMouseRect(window, null);
}

///////////////////////////////////////////////////////////////////////////////


faultdef 
	GPU_COMMAND_BUFFER_ACQUIRE_FAILED,
	GPU_COMMAND_BUFFER_SUBMIT_FAILED,
	GPU_TRANSFER_BUFFER_CREATE_FAILED,
	GPU_TRANSFER_BUFFER_MAP_FAILED;

struct GPUBufferCopyDescription
{
	SdlGPUBuffer* buffer;
	void* data;
	uint data_size;
}

fn void? copy_to_gpu_buffer(SdlGPUDevice* gpu, GPUBufferCopyDescription ...descriptions)
{
	uint total_size;
	foreach (d : descriptions)
	{
		total_size += d.data_size;
	}

	SdlGPUCommandBuffer* command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
	if (!command_buffer)
	{
		sdl_error("failed to acquire gpu command buffer");
		return GPU_COMMAND_BUFFER_ACQUIRE_FAILED~;
	}

	{
		SdlGPUCopyPass* copy_pass = sdl3::beginGPUCopyPass(command_buffer);
		defer sdl3::endGPUCopyPass(copy_pass);

		{
			SdlGPUTransferBuffer* transfer_buffer = sdl3::createGPUTransferBuffer(gpu, &&{ .usage = UPLOAD, .size = total_size });
			if (!transfer_buffer)
			{
				sdl_error("failed to create gpu transfer buffer");
				return GPU_TRANSFER_BUFFER_CREATE_FAILED~;
			}
			defer sdl3::releaseGPUTransferBuffer(gpu, transfer_buffer);

			{
				void* transfer_mem = sdl3::mapGPUTransferBuffer(gpu, transfer_buffer, false);
				if (!transfer_mem)
				{
					sdl_error("failed to map gpu transfer buffer");
					return GPU_TRANSFER_BUFFER_MAP_FAILED~;
				}
				defer sdl3::unmapGPUTransferBuffer(gpu, transfer_buffer);

				uint offset;
				foreach (d : descriptions)
				{
					mem::copy(transfer_mem[offset:d.data_size], d.data, d.data_size);
					offset += d.data_size;
				}
			}

			uint offset;
			foreach (d : descriptions)
			{
				sdl3::uploadToGPUBuffer(
					copy_pass,
					&&{ .transfer_buffer = transfer_buffer, .offset = offset },
					&&{ .buffer = d.buffer, .offset = 0, .size = d.data_size },
					false,
				);
				offset += d.data_size;
			}
		}
	}

	if (!sdl3::submitGPUCommandBuffer(command_buffer))
	{
		sdl_error("failed to submit command buffer");
		return GPU_COMMAND_BUFFER_SUBMIT_FAILED~;
	}
}

struct GPUTextureCopyDescription
{
	SdlGPUTexture* texture;
	void* data;
	int data_size;
	int width;
	int height;
}

fn void? copy_to_gpu_texture(SdlGPUDevice* gpu, GPUTextureCopyDescription ...descriptions)
{
	uint total_size;
	foreach (d : descriptions)
	{
		total_size += d.data_size;
	}

	SdlGPUCommandBuffer* command_buffer = sdl3::acquireGPUCommandBuffer(gpu);
	if (!command_buffer)
	{
		sdl_error("failed to acquire gpu command buffer");
		return GPU_COMMAND_BUFFER_ACQUIRE_FAILED~;
	}

	{
		SdlGPUCopyPass* copy_pass = sdl3::beginGPUCopyPass(command_buffer);
		defer sdl3::endGPUCopyPass(copy_pass);

		{
			SdlGPUTransferBuffer* transfer_buffer = sdl3::createGPUTransferBuffer(gpu, &&{ .usage = UPLOAD, .size = total_size });
			if (!transfer_buffer)
			{
				sdl_error("failed to create gpu transfer buffer");
				return GPU_TRANSFER_BUFFER_CREATE_FAILED~;
			}
			defer sdl3::releaseGPUTransferBuffer(gpu, transfer_buffer);

			{
				void* transfer_mem = sdl3::mapGPUTransferBuffer(gpu, transfer_buffer, false);
				if (!transfer_mem)
				{
					sdl_error("failed to map gpu transfer buffer");
					return GPU_TRANSFER_BUFFER_MAP_FAILED~;
				}
				defer sdl3::unmapGPUTransferBuffer(gpu, transfer_buffer);

				uint offset;
				foreach (d : descriptions)
				{
					mem::copy(transfer_mem[offset:d.data_size], d.data, d.data_size);
					offset += d.data_size;
				}
			}

			uint offset;
			foreach (d : descriptions)
			{
				sdl3::uploadToGPUTexture(
					copy_pass,
					&&{ .transfer_buffer = transfer_buffer, .offset = offset },
					&&{ .texture = d.texture, .w = d.width, .h = d.height, .d = 1 },
					false,
				);
				offset += d.data_size;
			}
		}
	}

	if (!sdl3::submitGPUCommandBuffer(command_buffer))
	{
		sdl_error("failed to submit command buffer");
		return GPU_COMMAND_BUFFER_SUBMIT_FAILED~;
	}
}

faultdef
	IO_FROM_MEM_FAILED,
	IMAGE_LOAD_FAILED;

fn SdlSurface*? load_image_from_memory(char[] data)
{
	SdlIOStream* io_stream = sdl3::fromConstMemIO(&data[0], data.len);
	if (!io_stream)
	{
		sdl_error("failed to create io stream from data");
		return IO_FROM_MEM_FAILED~;
	}

	SdlSurface* surface = sdl3_image::loadIO(io_stream, true);
	if (!surface)
	{
		sdl_error("failed to load image from io stream");
		return IMAGE_LOAD_FAILED~;
	}

	return surface;
}

fn SdlSurface*? load_image_from_file(char* file_path)
{
	SdlSurface* surface = sdl3_image::load(file_path);
	if (!surface)
	{
		sdl_error("failed to load image from file");
		return IMAGE_LOAD_FAILED~;
	}

	return surface;
}

faultdef
	TEXTURE_LOAD_UNSPECIFIED_SOURCE,
	TEXTURE_LOAD_CREATE_FAILED;

struct GPULoadTextureDescription
{
	SdlGPUTexture** texture;
	char[] image_source;
	char*  image_path;
}

fn SdlGPUTexture*? load_texture(SdlGPUDevice* gpu, char[] image_source)
{
	SdlSurface* surface;
	if (image_source)
	{
		surface = load_image_from_memory(image_source)!!;
	}
	else
	{
		return TEXTURE_LOAD_UNSPECIFIED_SOURCE~;
	}
	defer sdl3::destroySurface(surface);

	SdlGPUTexture* texture = sdl3::createGPUTexture(
		gpu,
		&&{
			.type = T2D,
			.format = R8G8B8A8_UNORM,
			.usage = { .sampler = true },
			.width = surface.w,
			.height = surface.h,
			.layer_count_or_depth = 1,
			.num_levels = 1,
		},
	);
	if (!texture)
	{
		sdl_error("failed to create gpu texture");
		return TEXTURE_LOAD_CREATE_FAILED~;
	}

	copy_to_gpu_texture(
		gpu,
		{ texture, surface.pixels, surface.pitch*surface.h, surface.w, surface.h },
	)!!;

	return texture;
}

faultdef
	TEXTURE_DEPTH_STENCIL_CREATE_FAILED;

fn void? update_depth_stencil_texture(SdlGPUDevice* gpu, DepthStencilTextureInfo* depth_texture_info, int window_width, int window_height)
{
	if (depth_texture_info.texture)
	{
		if (depth_texture_info.current_width >= window_width && depth_texture_info.current_height >= window_height) return;

		sdl3::releaseGPUTexture(gpu, depth_texture_info.texture);
		depth_texture_info.texture = null;
	}

	depth_texture_info.current_width = window_width;
	depth_texture_info.current_height = window_height;
	depth_texture_info.texture = sdl3::createGPUTexture(
		gpu,
		&&{
			.type = T2D,
			.format = DEPTH_TEXTURE_FORMAT,
			.usage = { .depth_stencil_target = true },
			.width = depth_texture_info.current_width,
			.height = depth_texture_info.current_height,
			.layer_count_or_depth = 1,
			.num_levels = 1,
		},
	);
	if (!depth_texture_info.texture) return TEXTURE_DEPTH_STENCIL_CREATE_FAILED~;
}

macro sdl_error(String msg)
{
	ZString sdlerr = (ZString)sdl3::getError();
	io::printfn("%s: %s", msg, sdlerr);
}

macro float ticks_s() => (float)sdl3::getTicks() / 1000.0;
fn float to_rad(float degrees) => math::deg_to_rad(degrees);


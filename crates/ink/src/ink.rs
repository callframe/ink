use glfw_sys::{GLFW_TRUE, glfwInit};
use mimalloc::MiMalloc;

#[global_allocator]
static ALLOC: MiMalloc = MiMalloc;

fn main() {
    if unsafe { glfwInit() } as u32 != GLFW_TRUE {
        panic!("Failed to initialize GLFW");
    }

    unsafe { glfw_sys::glfwTerminate() };
}

use glfw_sys::{GLFW_TRUE, glfwInit, glfwTerminate};
use mimalloc::MiMalloc;

use crate::editor::Editor;

mod editor;

#[global_allocator]
static ALLOC: MiMalloc = MiMalloc;

fn main() {
    if unsafe { glfwInit() } as u32 != GLFW_TRUE {
        panic!("Failed to initialize GLFW");
    }

    let editor = match Editor::new() {
        Ok(editor) => editor,
        Err(e) => panic!("Failed to create editor: {:?}", e),
    };

    editor.run();

    unsafe { glfwTerminate() };
}

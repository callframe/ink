use std::{
    collections::HashSet,
    ffi::{self, CStr},
    ptr,
};

use glam::IVec2;
use glfw_sys::{
    GLFWwindow, glfwCreateWindow, glfwGetWindowUserPointer, glfwPollEvents,
    glfwSetWindowCloseCallback, glfwSetWindowUserPointer,
};
use hecs::World;

static MAIN_WINDOW_DIMS: IVec2 = IVec2::new(800, 600);
static MAIN_WINDOW_TITLE: &'static CStr = unsafe {
    CStr::from_bytes_with_nul_unchecked(concat!(env!("CARGO_PKG_NAME"), "\0").as_bytes())
};

#[derive(Debug)]
pub enum EditorError {
    FailedToCreateWindow,
}

#[unsafe(no_mangle)]
extern "C" fn handle_window_close(window: *mut GLFWwindow) {
    let editor_ptr = unsafe { glfwGetWindowUserPointer(window) as *mut Editor };
    assert_ne!(editor_ptr, ptr::null_mut());

    let editor_ref = unsafe { &mut *editor_ptr };
    editor_ref.windows.remove(&window);
}

pub struct Editor {
    windows: HashSet<*mut GLFWwindow>,
    world: World,
}

impl Editor {
    pub fn new() -> Result<Box<Self>, EditorError> {
        let window_ptr = unsafe {
            glfwCreateWindow(
                MAIN_WINDOW_DIMS.x,
                MAIN_WINDOW_DIMS.y,
                MAIN_WINDOW_TITLE.as_ptr(),
                ptr::null_mut(),
                ptr::null_mut(),
            )
        };

        if window_ptr.is_null() {
            return Err(EditorError::FailedToCreateWindow);
        }

        let mut windows = HashSet::new();
        windows.insert(window_ptr);

        let editor = Box::new(Self {
            windows,
            world: World::new(),
        });

        let editor_ptr = editor.as_ref() as *const Self as *mut Self;

        unsafe { glfwSetWindowUserPointer(window_ptr, editor_ptr as *mut ffi::c_void) };
        unsafe { glfwSetWindowCloseCallback(window_ptr, Some(handle_window_close)) };

        Ok(editor)
    }

    pub fn run(&self) {
        while self.windows.len() > 0 {
            unsafe { glfwPollEvents() };
        }
    }
}

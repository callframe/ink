use crate::handles::handle_window_close;
use glam::IVec2;
use glfw_sys::{
    glfwCreateWindow,
    glfwPollEvents,
    glfwSetWindowCloseCallback,
    glfwSetWindowUserPointer,
};
use hecs::World;
use std::{
    ffi::{
        self,
        CStr,
    },
    ptr,
};

use crate::handles::WindowHandle;

static MAIN_WINDOW_DIMS: IVec2 = IVec2::new(800, 600);
static MAIN_WINDOW_TITLE: &'static CStr =
    unsafe { CStr::from_bytes_with_nul_unchecked(concat!(env!("CARGO_PKG_NAME"), "\0").as_bytes()) };

#[derive(Debug)]
pub enum EditorError
{
    FailedToCreateWindow,
}

pub struct Editor
{
    pub world: World,
}

impl Editor
{
    pub fn new() -> Result<Box<Self>, EditorError>
    {
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

        let mut world = World::new();
        let _ = world.spawn((WindowHandle(window_ptr),));

        let editor = Box::new(Self { world: World::new() });
        let editor_ptr = editor.as_ref() as *const Self as *mut Self;

        unsafe { glfwSetWindowUserPointer(window_ptr, editor_ptr as *mut ffi::c_void) };
        unsafe { glfwSetWindowCloseCallback(window_ptr, Some(handle_window_close)) };

        Ok(editor)
    }

    pub fn run(&self)
    {
        let mut any_windows = false;
        let mut all_windows = self.world.query::<&WindowHandle>();

        for _ in &mut all_windows {
            any_windows = true;
        }

        if !any_windows {
            return;
        }

        unsafe { glfwPollEvents() };
    }
}

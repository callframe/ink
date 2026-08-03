use crate::editor::Editor;
use glfw_sys::{
    GLFWwindow,
    glfwDestroyWindow,
    glfwGetWindowUserPointer,
};
use hecs::Entity;
use std::ptr;

pub struct WindowHandle(pub *mut GLFWwindow);

unsafe impl Send for WindowHandle {}
unsafe impl Sync for WindowHandle {}

impl Drop for WindowHandle
{
    fn drop(&mut self)
    {
        unsafe {
            glfwDestroyWindow(self.0);
        }
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn handle_window_close(window: *mut GLFWwindow)
{
    let editor_ptr = unsafe { glfwGetWindowUserPointer(window) as *mut Editor };
    assert_ne!(editor_ptr, ptr::null_mut());
    let editor_ref = unsafe { &mut *editor_ptr };

    let found_entity = {
        let mut query = editor_ref.world.query::<(Entity, &WindowHandle)>();
        query
            .iter()
            .find(|(_, window_handle)| window_handle.0 == window)
            .map(|(entity, _)| entity)
    };

    if let Some(entity) = found_entity {
        editor_ref.world.despawn(entity).unwrap();
    }
}

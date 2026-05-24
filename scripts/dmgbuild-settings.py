app_path = defines["app_path"]
background_path = defines["background_path"]
volume_icon = defines["volume_icon"]

format = "UDZO"
filesystem = "HFS+"
size = "64M"
compression_level = 9

files = [(app_path, "HermesManager.app")]
symlinks = {"Applications": "/Applications"}
icon = volume_icon
background = background_path

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False

window_rect = ((100, 100), (660, 422))
default_view = "icon-view"
show_icon_preview = False
include_icon_view_settings = True
arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
label_pos = "bottom"
text_size = 12
icon_size = 180
icon_locations = {
    "HermesManager.app": (180, 172),
    "Applications": (480, 172),
}

def create_hook(mount_point, options):
    import os
    import subprocess

    app_in_image = os.path.join(mount_point, "HermesManager.app")
    subprocess.call(["/usr/bin/xattr", "-cr", app_in_image])
    subprocess.check_call(["/usr/bin/codesign", "--force", "--deep", "--sign", "-", app_in_image])

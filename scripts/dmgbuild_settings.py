format = "UDZO"
filesystem = "HFS+"
size = "18M"

files = [defines["app"]]
symlinks = {
    "Applications": "/Applications",
}

background = defines["background"]
window_rect = ((120, 120), (680, 420))
default_view = "icon-view"
show_toolbar = False
show_status_bar = False
show_sidebar = False
show_pathbar = False
show_tab_view = False

icon_size = 96
text_size = 13
label_pos = "bottom"
arrange_by = None
grid_spacing = 100
scroll_position = (0, 0)

icon_locations = {
    "Battery Panic.app": (190, 230),
    "Applications": (490, 230),
}

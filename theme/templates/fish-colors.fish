# Source this file from conf.d after Matugen generates it.
set -g fish_color_normal '{{colors.on_surface.default.hex_stripped}}'
set -g fish_color_command '{{colors.primary.default.hex_stripped}}' --bold
set -g fish_color_keyword '{{colors.tertiary.default.hex_stripped}}'
set -g fish_color_quote '{{colors.secondary.default.hex_stripped}}'
set -g fish_color_redirection '{{colors.primary_fixed_dim.default.hex_stripped}}'
set -g fish_color_end '{{colors.tertiary.default.hex_stripped}}'
set -g fish_color_error '{{colors.error.default.hex_stripped}}' --bold
set -g fish_color_param '{{colors.on_surface_variant.default.hex_stripped}}'
set -g fish_color_comment '{{colors.outline.default.hex_stripped}}' --italics
set -g fish_color_selection --background='{{colors.primary_container.default.hex_stripped}}'
set -g fish_color_search_match --background='{{colors.secondary_container.default.hex_stripped}}'
set -g fish_color_operator '{{colors.tertiary.default.hex_stripped}}'
set -g fish_color_escape '{{colors.secondary.default.hex_stripped}}'
set -g fish_color_autosuggestion '{{colors.outline.default.hex_stripped}}'
set -g fish_pager_color_prefix '{{colors.primary.default.hex_stripped}}' --bold
set -g fish_pager_color_completion '{{colors.on_surface.default.hex_stripped}}'
set -g fish_pager_color_description '{{colors.on_surface_variant.default.hex_stripped}}'
set -g fish_pager_color_selected_background --background='{{colors.surface_container_high.default.hex_stripped}}'

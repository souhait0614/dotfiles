-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

config.font = wezterm.font 'PlemolJP Console NF'

-- and finally, return the configuration to wezterm
return config

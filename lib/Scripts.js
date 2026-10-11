.pragma library

// Builds the command array that runs an island script (scripts/).
// ~/.config/archisland/scripts (install.sh's copy) is used first, otherwise
// scripts/ in the plugin folder. Arguments are not embedded into the shell
// as text but passed as separate argv entries, so quoting/special characters
// cause no trouble.
function command(pluginDir, name, args) {
  return ["bash", "-c",
    's="$HOME/.config/archisland/scripts/$1"; [ -f "$s" ] || s="$2/scripts/$1"; shift 2; exec "$s" "$@"',
    "archisland-script", name, pluginDir].concat(args || [])
}

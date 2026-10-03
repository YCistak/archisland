.pragma library

// Island betiklerini (scripts/) çalıştıracak komut dizisini kurar.
// Önce ~/.config/archisland/scripts (install.sh'nin kopyası), yoksa eklenti
// klasöründeki scripts/ kullanılır. Argümanlar kabuğa metin olarak
// gömülmez, ayrı argv olarak geçer; tırnak/özel karakter sorunu olmaz.
function command(pluginDir, name, args) {
  return ["bash", "-c",
    's="$HOME/.config/archisland/scripts/$1"; [ -f "$s" ] || s="$2/scripts/$1"; shift 2; exec "$s" "$@"',
    "archisland-betik", name, pluginDir].concat(args || [])
}

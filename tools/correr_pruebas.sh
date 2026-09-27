#!/bin/bash
# Corre todas las pruebas automaticas del juego (Git Bash en Windows o Linux).
# Uso:  bash tools/correr_pruebas.sh
# Si Godot no esta en el PATH:  GODOT="/c/ruta/a/Godot_v4.7.2-stable_win64_console.exe" bash tools/correr_pruebas.sh
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
FALLOS=0
for t in dialogue demo story save audio robustez sistemas libre; do
	printf "%-10s " "$t"
	salida=$("$GODOT" --headless --path . "res://tools/tests/test_$t.tscn" 2>&1 | grep -E "^TEST|FALLO")
	echo "$salida" | grep -q "FALLO" && FALLOS=$((FALLOS + 1))
	echo "$salida" | head -3
done
echo
[ "$FALLOS" -eq 0 ] && echo "Todas las pruebas pasaron." || echo "Pruebas con fallos: $FALLOS"

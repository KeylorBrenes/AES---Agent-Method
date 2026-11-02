#!/usr/bin/env bash
# AES 1.1.0 — Hook Stop (capa L2).
# Impide que el agente termine con pruebas fallando. Bloquea UNA sola vez:
# si ya se está continuando por este hook (stop_hook_active=true), deja terminar
# para evitar bucles infinitos; en ese caso el agente debe reportar BLOCKED.
# Ajustar AES_TEST_CMD al comando del proyecto. Requiere jq.
input=$(cat)
if [[ "$(jq -r '.stop_hook_active // false' <<< "$input")" == "true" ]]; then
  exit 0
fi

cmd="${AES_TEST_CMD:-npm test --silent}"
if ! out=$(bash -c "$cmd" 2>&1); then
  {
    echo "AES: hay pruebas fallando. Corrígelas sin modificar pruebas protegidas,"
    echo "o detente y reporta BLOCKED con la causa. Últimas líneas de la salida:"
    tail -n 20 <<< "$out"
  } >&2
  exit 2
fi
exit 0

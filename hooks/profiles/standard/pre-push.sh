#!/bin/sh
# rn-harness pre-push — perfil standard (quality:full + Android)
set -e
echo "-> quality:full..."
pnpm quality:full
printf "Testou no Android fisico? [y/N] "
read -r ans
case "$ans" in
  y|Y) ;;
  *) echo "ERRO: Teste no Android fisico antes de push."; exit 1 ;;
esac
echo "OK push liberado [standard]"

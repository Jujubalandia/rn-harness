#!/bin/sh
# rn-harness pre-push — perfil minimal (confirmacao Android somente)
set -e
printf "Testou no Android fisico? [y/N] "
read -r ans
case "$ans" in
  y|Y) ;;
  *) echo "ERRO: Teste no Android fisico antes de push."; exit 1 ;;
esac
echo "OK push liberado [minimal]"

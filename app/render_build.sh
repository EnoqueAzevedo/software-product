#!/usr/bin/env bash

# Instala o Flutter estável no ambiente do Render
git clone https://github.com/flutter/flutter.git --depth 1 --branch stable /tmp/flutter

# Adiciona o Flutter ao PATH
export PATH="/tmp/flutter/bin:$PATH"

# Ativa suporte ao Flutter Web
flutter config --enable-web

# Instala as dependências
flutter pub get

# Gera a versão web de produção
flutter build web --release
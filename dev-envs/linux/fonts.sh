#!/bin/bash -l
IFS=$'\n\t'
set -euxo pipefail

fonts_dir="${HOME}/.local/share/fonts"
mkdir -p "${fonts_dir}"

NE_VERSION="15046272"
curl -LO https://github.com/googlefonts/noto-emoji/files/${NE_VERSION}/Noto_Emoji.zip
unzip Noto_Emoji.zip -d /NotoEmoji
mv /NotoEmoji/static/* "${fonts_dir}"
rm -rf /NotoEmoji Noto_Emoji.zip

CC_VERSION="2404.23"
curl -LO https://github.com/microsoft/cascadia-code/releases/download/v${CC_VERSION}/CascadiaCode-${CC_VERSION}.zip
unzip CascadiaCode-${CC_VERSION}.zip -d /CascadiaCode
mv /CascadiaCode/ttf/static/CascadiaMonoNF-*.ttf "${fonts_dir}"
rm -rf /CascadiaCode CascadiaCode-${CC_VERSION}.zip

NF_VERSION="3.2.1"
curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}/FiraCode.zip
unzip FiraCode.zip -d /FiraCode
mv /FiraCode/FiraCodeNerdFont-*.ttf "${fonts_dir}"
mv /FiraCode/FiraCodeNerdFontMono-*.ttf "${fonts_dir}"
rm -rf /FiraCode FiraCode.zip

curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}/FiraMono.zip
unzip FiraMono.zip -d /FiraMono
mv /FiraMono/FiraMonoNerdFont-*.otf "${fonts_dir}"
rm -rf /FiraMono FiraMono.zip

#!/bin/bash
set -e
set -v

cp ~/.zshrc assets/

docker build -t mickvdv/toolbox . 

docker images

docker push mickvdv/toolbox

docker run -it mickvdv/toolbox
 
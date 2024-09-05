#!/bin/bash
set -e

docker build -t mickvdv/toolbox . 

docker images

docker push mickvdv/toolbox



docker run -it mickvdv/toolbox
 
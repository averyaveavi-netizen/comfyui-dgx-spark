# ============================================================================
# Dockerfile — ComfyUI optimisé pour DGX Spark (GB10, aarch64, CUDA 13)
#
# Choix « optimisé DGX Spark » :
#   - Base CUDA 13.0 officielle NVIDIA en arm64.
#   - PyTorch = LA build prouvée fonctionnelle sur ce GB10 : torch 2.9.0+cu130
#     (venv jupyterlab). Sa arch_list inclut sm_120 + compute_120 ; le PTX
#     compute_120 est JIT-compilé vers le sm_121 réel du GB10 (Blackwell).
#     C'est pour ça qu'on épingle EXACTEMENT ces versions, pas une image
#     ComfyUI publique (quasi jamais buildée pour sm_121 + ARM64).
#
# Rebuild :  cd ~/docker && docker compose build comfyui
# ============================================================================
FROM nvidia/cuda:13.0.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1 \
    # Wheels NVIDIA aarch64 = gros → timeouts généreux (cf. reste du stack)
    PIP_DEFAULT_TIMEOUT=900

# Dépendances système : python, git (clone ComfyUI + custom nodes),
# libGL/glib (opencv), build-essential (compilation de certains custom nodes).
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv git \
        build-essential \
        libgl1 libglib2.0-0 \
        ffmpeg curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Torch AVANT ComfyUI, épinglé sur la build cu130 prouvée sur ce GB10.
RUN python3 -m pip install --break-system-packages \
        --extra-index-url https://download.pytorch.org/whl/cu130 \
        torch==2.9.0+cu130 torchvision==0.24.0 torchaudio==2.9.0

# ComfyUI (dernière version) + ComfyUI-Manager (installation de nodes/modèles
# depuis l'UI). Le code vit dans l'image ; les DONNÉES sont des bind mounts.
WORKDIR /opt
RUN git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git \
    && git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git \
        ./data/custom_nodes/ComfyUI-Manager

WORKDIR /opt/ComfyUI
# Requirements de ComfyUI + du Manager. --extra-index-url conservé pour que
# toute dépendance torch reste sur cu130 (jamais la roue CPU par défaut).
RUN python3 -m pip install --break-system-packages \
        --extra-index-url https://download.pytorch.org/whl/cu130 \
        -r requirements.txt \
        -r custom_nodes/ComfyUI-Manager/requirements.txt

EXPOSE 8188

# --listen 127.0.0.1 : ComfyUI n'écoute qu'en localhost sur l'hôte
# (network_mode host) ; l'accès réseau passe EXCLUSIVEMENT par nginx.
# Les dossiers de données sont redirigés via --base-directory (bind mount).
CMD ["python3", "main.py", \
     "--listen", "127.0.0.1", "--port", "8188", \
     "--base-directory", "/data"]

# ComfyUI on NVIDIA DGX Spark (Docker)

**English** · [Français](#comfyui-sur-nvidia-dgx-spark-docker)

Docker stack to run **ComfyUI** — optimally — on an **NVIDIA DGX Spark**
(**GB10 / Blackwell** chip, **ARM64/aarch64**, Ubuntu 24.04, CUDA 13).

### Why a dedicated image?
Public ComfyUI images are essentially never built for **`sm_121` + ARM64**. This one
pins the **proven** working stack for the GB10: base `nvidia/cuda:13.0.1-runtime-ubuntu24.04`
(arm64) + **`torch 2.9.0+cu130`** — its `arch_list` includes `sm_120`/`compute_120`, and the
`compute_120` PTX is JIT-compiled to the GB10's real `sm_121` (Blackwell). ComfyUI +
**ComfyUI-Manager** are baked into the image; your data lives in a bind mount.

The compose file also bakes in three fixes learned the hard way (see comments):
`--enable-assets`, a persistent sqlite DB in `/data/db`, and PEP 668 env vars so
**ComfyUI-Manager can actually install custom-node dependencies**.

---

## 1. Prerequisites (on the host)

- **Hardware**: NVIDIA DGX Spark (GB10). *Built for this ARM64/Blackwell architecture.*
- **NVIDIA driver** 580.x or newer.
- **Docker Engine** + **Docker Compose v2**, and the **NVIDIA Container Toolkit**:
  ```bash
  docker run --rm --gpus all nvidia/cuda:13.0.1-runtime-ubuntu24.04 nvidia-smi
  ```

## 2. Installation

```bash
cp .env.example .env          # (optional) paste an HF_TOKEN for gated models
docker compose build          # builds torch cu130 + ComfyUI + Manager (long-ish)
docker compose up -d
docker compose logs -f
```

## 3. Where to put your models

Your data (models, outputs, custom nodes, DB) lives in **`./data`** (bind mount → `/data`):

```
./data/
├── models/
│   ├── checkpoints/        # all-in-one checkpoints
│   ├── diffusion_models/   # Flux / SD3 / Wan / Z-Image (UNET-only)
│   ├── text_encoders/      # clip_l, t5xxl, umt5, mistral, qwen...
│   ├── vae/
│   └── loras/
├── custom_nodes/           # extra nodes (or install them via the Manager)
├── input/  output/  user/  db/
```
Drop model files into the matching `./data/models/<type>/` folder, then hit **R** in the
UI (or reload) to refresh the list. Most folders are created automatically on first run.

## 4. Access

ComfyUI listens on **`127.0.0.1:8188`** (localhost only — it has **no authentication**).

- On the machine: <http://localhost:8188>
- Remotely (safe): SSH tunnel → `ssh -L 8188:127.0.0.1:8188 user@dgx`, then <http://localhost:8188>
- On the LAN: use the optional reverse proxy in **`nginx/comfyui.conf`** (HTTP :8080), or
  change `--listen` to `0.0.0.0` in `compose.yaml`.
  **⚠️ ComfyUI has no auth — only expose it on a trusted network.**

## 5. Custom nodes & models via ComfyUI-Manager

The **Manager** is included. Use it to install missing custom nodes (their pip deps install
correctly thanks to the PEP 668 env vars) and to download models **server-side** into
`./data/models/`. After installing nodes, use the Manager's **Restart** button.

## 6. Troubleshooting

- **`could not select device driver ... gpu`** → NVIDIA Container Toolkit missing/misconfigured.
- **Custom-node install fails on `externally-managed-environment`** → the `UV_BREAK_SYSTEM_PACKAGES`
  / `PIP_BREAK_SYSTEM_PACKAGES` env vars (already set) fix this; make sure you didn't remove them.
- **Empty "Assets" tab** → needs `--enable-assets` (already set) + the sqlite DB in `/data/db`.
- **Generated images vanish on restart** → those were `Preview Image` outputs (temp, wiped on
  restart). Use **`Save Image`** → they persist in `./data/output/`.

## 7. Package contents

```
comfyui-dgx-spark/
├── Dockerfile          # image (torch cu130 for sm_121 + ComfyUI + Manager)
├── compose.yaml        # service + GPU + fixes (assets / db / PEP668) + volumes
├── .env.example        # HF_TOKEN template
├── nginx/comfyui.conf  # (optional) LAN reverse proxy on :8080
└── README.md           # this file
```

> This package ships the **Docker config only** — no workflows, no models.

---
---

# ComfyUI sur NVIDIA DGX Spark (Docker)

[English](#comfyui-on-nvidia-dgx-spark-docker) · **Français**

Pile Docker pour faire tourner **ComfyUI** — de façon optimale — sur une **NVIDIA DGX Spark**
(puce **GB10 / Blackwell**, **ARM64/aarch64**, Ubuntu 24.04, CUDA 13).

### Pourquoi une image dédiée ?
Les images ComfyUI publiques ne sont quasiment jamais buildées pour **`sm_121` + ARM64**.
Celle-ci épingle la stack **prouvée** sur le GB10 : base `nvidia/cuda:13.0.1-runtime-ubuntu24.04`
(arm64) + **`torch 2.9.0+cu130`** — sa `arch_list` inclut `sm_120`/`compute_120`, et le PTX
`compute_120` est JIT-compilé vers le vrai `sm_121` du GB10 (Blackwell). ComfyUI +
**ComfyUI-Manager** sont dans l'image ; tes données sont dans un bind mount.

Le compose intègre aussi trois correctifs appris à la dure (voir commentaires) :
`--enable-assets`, une BD sqlite persistante dans `/data/db`, et les vars PEP 668 pour que
**ComfyUI-Manager puisse réellement installer les dépendances des custom nodes**.

---

## 1. Prérequis (sur l'hôte)

- **Matériel** : NVIDIA DGX Spark (GB10). *Conçu pour cette architecture ARM64/Blackwell.*
- **Pilote NVIDIA** 580.x ou plus.
- **Docker Engine** + **Docker Compose v2**, et le **NVIDIA Container Toolkit** :
  ```bash
  docker run --rm --gpus all nvidia/cuda:13.0.1-runtime-ubuntu24.04 nvidia-smi
  ```

## 2. Installation

```bash
cp .env.example .env          # (optionnel) colle un HF_TOKEN pour les modèles gated
docker compose build          # build torch cu130 + ComfyUI + Manager (un peu long)
docker compose up -d
docker compose logs -f
```

## 3. Où mettre tes modèles

Tes données (modèles, sorties, custom nodes, BD) vivent dans **`./data`** (bind mount → `/data`) :

```
./data/
├── models/
│   ├── checkpoints/        # checkpoints tout-en-un
│   ├── diffusion_models/   # Flux / SD3 / Wan / Z-Image (UNET seul)
│   ├── text_encoders/      # clip_l, t5xxl, umt5, mistral, qwen...
│   ├── vae/
│   └── loras/
├── custom_nodes/           # nodes additionnels (ou via le Manager)
├── input/  output/  user/  db/
```
Dépose les fichiers dans le dossier `./data/models/<type>/` correspondant, puis touche **R**
dans l'UI (ou recharge) pour rafraîchir la liste. La plupart des dossiers sont créés
automatiquement au premier lancement.

## 4. Accès

ComfyUI écoute sur **`127.0.0.1:8188`** (localhost uniquement — **aucune authentification**).

- Sur la machine : <http://localhost:8188>
- À distance (sûr) : tunnel SSH → `ssh -L 8188:127.0.0.1:8188 user@dgx`, puis <http://localhost:8188>
- Sur le LAN : utilise le reverse proxy optionnel **`nginx/comfyui.conf`** (HTTP :8080), ou
  passe `--listen` à `0.0.0.0` dans `compose.yaml`.
  **⚠️ ComfyUI n'a pas d'auth — ne l'expose que sur un réseau de confiance.**

## 5. Custom nodes & modèles via ComfyUI-Manager

Le **Manager** est inclus. Il installe les custom nodes manquants (leurs deps pip s'installent
correctement grâce aux vars PEP 668) et télécharge les modèles **côté serveur** dans
`./data/models/`. Après une install de nodes, utilise le bouton **Restart** du Manager.

## 6. Dépannage

- **`could not select device driver ... gpu`** → NVIDIA Container Toolkit absent/mal configuré.
- **Install de custom node qui échoue sur `externally-managed-environment`** → les vars
  `UV_BREAK_SYSTEM_PACKAGES` / `PIP_BREAK_SYSTEM_PACKAGES` (déjà présentes) corrigent ça ;
  vérifie que tu ne les as pas retirées.
- **Onglet "Assets" vide** → nécessite `--enable-assets` (déjà présent) + la BD sqlite dans `/data/db`.
- **Les images générées disparaissent au redémarrage** → c'étaient des sorties `Preview Image`
  (temporaires, vidées au redémarrage). Utilise **`Save Image`** → elles persistent dans `./data/output/`.

## 7. Contenu du package

```
comfyui-dgx-spark/
├── Dockerfile          # image (torch cu130 pour sm_121 + ComfyUI + Manager)
├── compose.yaml        # service + GPU + correctifs (assets / db / PEP668) + volumes
├── .env.example        # gabarit HF_TOKEN
├── nginx/comfyui.conf  # (optionnel) reverse proxy LAN sur :8080
└── README.md           # ce fichier
```

> Ce package fournit **uniquement la config Docker** — aucun workflow, aucun modèle.

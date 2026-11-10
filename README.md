# ComfyUI on NVIDIA DGX Spark (Docker)

**English** · [中文](#comfyui-nvidia-dgx-spark-docker)

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
git clone https://github.com/averyaveavi-netizen/comfyui-dgx-spark.git
cd comfyui-dgx-spark/

cp .env.example .env          # (optional) paste an HF_TOKEN for gated models
nano .env
HF_TOKEN=YOUR_KEY

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

# ComfyUI NVIDIA DGX Spark (Docker)

[English](#comfyui-on-nvidia-dgx-spark-docker) · **中文**

在 **NVIDIA DGX Spark**（**GB10 / Blackwell 晶片**、**ARM64/aarch64**、Ubuntu 24.04、CUDA 13）上以最佳效能運行 ComfyUI 的 Docker 技術堆疊。

### 為什麼需要專用映像檔？
公開的 ComfyUI 映像檔幾乎不會針對 **`sm_121` + ARM64**進行編譯。此映像檔經過本人驗證、可在 GB10 上穩定運作的環境配置：以 **nvidia/cuda:13.0.1-runtime-ubuntu24.04 (arm64)** 為基礎，搭配 **torch 2.9.0+cu130**——其 arch_list 包含 **sm_120 / compute_120**，且 compute_120 的 PTX 會透過即時編譯（JIT-compiled）轉換為 GB10 實際使用的 sm_121（Blackwell 架構）。ComfyUI 與 ComfyUI-Manager 已直接內建於映像檔中，而你的個人資料則透過綁定掛載（bind mount）儲存在本機。

Compose 設定檔中也內建了三個從實戰經驗中總結出的修正（詳見設定檔註解）：--enable-assets 參數、位於 /data/db 的 SQLite 資料庫，以及 PEP 668 環境變數，確保 ComfyUI-Manager 能夠順利安裝自訂節點（custom-node）的相依套件。

---

## 1. 前置條件需求（主機端）

- **硬體**：NVIDIA DGX Spark (GB10)。*專為此 ARM64/Blackwell 架構打造。*
- **NVIDIA 驅動程式**：580.x 或更新版本。
- **Docker Engine + Docker Compose v**，以及 **NVIDIA Container Toolkit** :
  ```bash
  docker run --rm --gpus all nvidia/cuda:13.0.1-runtime-ubuntu24.04 nvidia-smi
  ```

## 2. 安裝步驟

```bash
git clone https://github.com/averyaveavi-netizen/comfyui-dgx-spark.git
cd comfyui-dgx-spark/

cp .env.example .env          # (optional) paste an HF_TOKEN for gated models
nano .env
HF_TOKEN=YOUR_KEY

docker compose build          # builds torch cu130 + ComfyUI + Manager (long-ish)
docker compose up -d
docker compose logs -f
```

## 3. 模型存放位置

你的所有資料（模型、輸出圖片、自訂節點、資料庫）都存放在 **./data（綁定掛載至容器內的 /data）** (bind mount → `/data`) :

```
./data/
├── models/
│   ├── checkpoints/        # 整合式完整模型（All-in-one checkpoints）
│   ├── diffusion_models/   # Flux / SD3 / Wan / Z-Image（僅 UNET 部分）
│   ├── text_encoders/      # clip_l, t5xxl, umt5, mistral, qwen...
│   ├── vae/
│   └── loras/
├── custom_nodes/           # 額外擴充節點（或透過 Manager 安裝）
├── input/  output/  user/  db/
```
將模型檔案放入對應的 ./data/models/<類型>/ 資料夾後，在網頁介面上按 **R** 鍵（或重新整理網頁）即可更新模型清單。大多數資料夾會在首次啟動時自動建立。

## 4. 連線與存取方式

ComfyUI 預設監聽 **127.0.0.1:8188**（僅限本機連線——無內建身分驗證機制，需要的話可以修改成隨處可連結）。

- 在主機本機上：開啟 http://localhost:8188
- 遠端連線（安全做法）：建立 SSH 通道 → `ssh -L 8188:127.0.0.1:8188 user@dgx`，接著在本地瀏覽器開啟 http://localhost:8188
- 區域網路（LAN）內連線：可使用選用的反向代理設定 **nginx/comfyui.conf（HTTP :8080）**，或在 **compose.yaml** 中將 **--listen 改為 0.0.0.0**。

  **⚠️ ComfyUI 沒有密碼保護，請務必僅在受信任的網路環境中開放。**

## 5. 透過 ComfyUI-Manager 管理自訂節點與模型

此映像檔已內建 **Manager**。你可以用它來安裝缺少的自訂節點（受惠於 PEP 668 環境變數設定，其 pip 相依套件皆可正常安裝），並直接從伺服器端下載模型至 `./data/models/`。安裝完新節點後，請點擊 Manager 介面中的 **Restart** 按鈕重啟服務。

## 6. 疑難排解

- **`could not select device driver ... gpu`** → 代表尚未安裝 NVIDIA Container Toolkit 或設定有誤。
- **安裝自訂節點時因 `externally-managed-environment`失敗：** → 預設已設定  `UV_BREAK_SYSTEM_PACKAGES` / `PIP_BREAK_SYSTEM_PACKAGES` 環境變數來解決此問題，請確認你沒有將其移除。
- **「Assets」分頁顯示空白** → 需要啟用 `--enable-assets`（已預設開啟）並確保 `/data/db` 中有 SQLite 資料庫。  
- **重啟後生成的圖片消失** → 那些是  `Preview Image` 節點的輸出（暫存檔案，重啟即清除）。請改用 **`Save Image`** 節點，圖片才會永久保存在  `./data/output/` 中。

## 7. 套件內容結構

```
comfyui-dgx-spark/
├── Dockerfile          # 映像檔建置檔（適用於 sm_121 的 torch cu130 + ComfyUI + Manager）
├── compose.yaml        # 服務設定 + GPU 配置 + 修正項目（assets / db / PEP668）+ 磁碟區掛載
├── .env.example        # HF_TOKEN 環境變數範本
├── nginx/comfyui.conf  # （選用）監聽 :8080 連接埠的區域網路反向代理設定
└── README.md           # 本說明文件
```

> 本套件僅包含 **Docker 設定檔**——不包含任何 **工作流（workflows）** 或 **模型檔案**。

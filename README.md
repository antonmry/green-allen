# Green Allen

This project is local/docker environment focused on performance and reducing
CO2 emissions of the CERN [lhcb Allen](https://gitlab.cern.ch/lhcb/Allen)
system.

The Docker image is based on [the Dockerfile in the official repository](https://gitlab.cern.ch/lhcb/Allen/-/raw/master/.devcontainer/Dockerfile?ref_type=heads).

## Requirements

It requires the [Nvidia Container
Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
In the particular case of Fedora, follow [these
instructions](https://rpmfusion.org/Howto/CUDA).

```sh
sudo dnf config-manager addrepo --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/fedora42/$(uname -m)/cuda-fedora42.repo
sudo dnf clean all
sudo dnf config-manager setopt cuda-fedora42-$(uname -m).exclude=nvidia-driver,nvidia-modprobe,nvidia-persistenced,nvidia-settings,nvidia-libXNVCtrl,nvidia-xconfig
sudo dnf -y install cuda-toolkit xorg-x11-drv-nvidia-cuda

sudo dnf copr enable @ai-ml/nvidia-container-toolkit
sudo dnf install nvidia-container-toolkit nvidia-container-toolkit-selinux
sudo nvidia-ctk cdi generate -output /etc/cdi/nvidia.yaml

podman run --device nvidia.com/gpu=all --rm nvidia/cuda:12.2.0-devel-rockylinux9 nvidia-smi
```

## Setup

- Run `./download_allen.sh` to download the upstream Allen repository into the
  `Allen/` directory. The script exits early with a message when the folder
  already exists.
- Run 

```bash
podman build -t green-allen-build:latest .
podman run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest nvidia-smi
podman run --rm -it --userns=keep-id:uid=1000,gid=1000 --gpus all -v "$PWD":/workspace:Z -w /workspace green-allen-build:latest bash
```

```bash
docker build -t green-allen-build:latest .
docker run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest nvidia-smi
docker run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest bash
```

## Plan

- [ ] Build local environment using Docker/Podman
- [ ] Run a program in Allen following [the official documentation](https://allen-doc.docs.cern.ch/setup/run_allen.html#standalone-allen)
- [ ] Add Github Actions to validate the build is working as expected after introducing changes
- [ ] Add proper monitoring for [performance following Allen documentation](https://allen-doc.docs.cern.ch/setup/performance.html#scripts-for-standalone-allen)
- [ ] Consider adding [general monitoring](https://allen-doc.docs.cern.ch/monitoring/monitoring_allen.html) too
- [ ] Try continuous profiling with Allen (including GPU profiling)

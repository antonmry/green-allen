# Green Allen

This project is local/docker environment focused on performance and reducing CO2
emissions of the CERN [lhcb Allen](https://gitlab.cern.ch/lhcb/Allen) system.

The Docker image is based on
[the Dockerfile in the official repository](https://gitlab.cern.ch/lhcb/Allen/-/raw/master/.devcontainer/Dockerfile?ref_type=heads).

## Requirements

It requires the
[Nvidia Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
In the particular case of Fedora, follow
[these instructions](https://rpmfusion.org/Howto/CUDA).

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

Run `./scripts/download_allen.sh` to download the upstream Allen repository into the
`Allen/` directory. The script exits early with a message when the folder
already exists.

Build the image and exec bash on it. Note that
[root](https://github.com/root-project/root) is downloaded and compiled during
the building process to use C++20 (required by Allen) and the build process
will take significant time.

With Podman/Fedora:

```bash
podman build -t green-allen-build:latest .
podman run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest nvidia-smi
podman run --rm -it --userns=keep-id:uid=1000,gid=1000 --gpus all -v "$PWD":/workspace:Z -w /workspace green-allen-build:latest bash
```

With Docker:

```bash
docker build -t green-allen-build:latest .
docker run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest nvidia-smi
docker run --rm -it --gpus all -v "$PWD":/workspace -w /workspace green-allen-build:latest bash
```

Inside the container, build Allen:

```bash
mkdir -p Allen/build
cd Allen/build
cmake -DSTANDALONE=ON ..
make
```

## Run Allen

Inside the container, run in `Allen/build` following the [Run Allen official
documentation](https://allen-doc.docs.cern.ch/setup/run_allen.html#standalone-allen)
with the following command:

```bash
./Allen --sequence hlt1_pp_default --mdf ../input/minbias/mdf/MiniBrunel_2018_MinBias_FTv4_DIGI_retinacluster_v1.mdf
```

### Longer standalone runs without external datasets

The bundled MDF above only contains 10 events. To stress the pipeline for longer without fetching extra inputs, run the helper script (from the repository root):

```bash
python3 scripts/prepare_long_run.py --repeat-count 20
```

This produces:
- `Allen/build/mdf_repeat.lst` pointing to the same MDF multiple times (reconfigure `--repeat-count` to scale the workload).
- `Allen/input/detector_configuration/magfield.bin`, a minimal zero-field grid that keeps standalone Allen running when the real field map is unavailable. Pass `--force` to overwrite existing files.

Then launch a longer test (adjust repetitions/threads as needed):

```bash
./Allen --sequence hlt1_pp_default --mdf mdf_repeat.lst \
        -g ../input/detector_configuration -t 4 --events-per-slice 1000 -r 200 -v 3
```

The synthetic `magfield.bin` is only for throughput or regression checks. Replace it with the real field map (e.g., from `/cvmfs/lhcb.cern.ch/lib/lhcb/DBASE/FieldMap/...`) before running physics validation studies.

## Plan

- [x] Build local environment using Docker/Podman
- [x] Run a program in Allen following
      [the official documentation](https://allen-doc.docs.cern.ch/setup/run_allen.html#standalone-allen)
- [ ] Add Github Actions to validate the build is working as expected after
      introducing changes
- [ ] Build Allen with GPU support and test it
- [ ] Add proper monitoring for
      [performance following Allen documentation](https://allen-doc.docs.cern.ch/setup/performance.html#scripts-for-standalone-allen)
- [ ] Consider adding
      [general monitoring](https://allen-doc.docs.cern.ch/monitoring/monitoring_allen.html)
      too
- [ ] Try continuous profiling with Allen (including GPU profiling)

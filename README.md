# Quantum ESPRESSO GPU Installation Guide (Google Colab/Ubuntu)

This repository provides a fully automated shell script (`qe_setup.sh`) to install the GPU-accelerated version of **Quantum ESPRESSO 7.4.1** using:

- **NVIDIA HPC SDK 25.3**
- **CUDA 12.8**
- **OpenMPI 4.1.5**
- **Intel MKL 2025.1**
- **FFTW3**

Tested on **Google Colab** and **Ubuntu 20.04/22.04**, targeting **NVIDIA T4 GPU (Compute Capability 7.5)**.

---

## 📁 Files

- `qe_setup.sh` — Main installation script

---

## 📦 What It Installs

1. System dependencies (BLAS, LAPACK, FFTW3)
2. NVIDIA HPC SDK with CUDA and OpenMPI
3. Intel MKL 2025.1
4. Quantum ESPRESSO 7.4.1

Make sure you:
- Are running this in a Linux environment (Colab or Ubuntu)
- Have sudo privileges (if on a local machine)
- ~50gb free space
---

## 🚀 How to Use

1. **Upload the following files to your environment:**

   - `qe_setup.sh` (this script)

2. **Give execution permission:**

   ```bash
   chmod +x qe_setup.sh
   ```

3. **Run the script:**

```bash
bash qe_setup.sh
```

---

## 🔧 Step-by-Step Breakdown

### 1. Install Dependencies
Updates APT and installs necessary development libraries:
```bash
sudo apt-get update
sudo apt-get install -y libblas-dev liblapack-dev libfftw3-dev liblapack-doc libfftw3-doc
```

### 2. Install NVIDIA HPC SDK (v25.3)
Downloads and extracts the SDK, then installs it silently:
```bash
wget https://developer.download.nvidia.com/hpc-sdk/25.3/nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
tar xpzf nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
cd nvhpc_2025_253_Linux_x86_64_cuda_12.8
printf "\n3\n\n" | ./install
```

### 3. Set Environment Variables
Sets `PATH`, `LD_LIBRARY_PATH`, `CPPFLAGS`, etc., for the compiler, CUDA, and MPI.
```bash
export HPC_BASE="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3"
export CUDA_VER="12.8"

export PATH="$HPC_BASE/comm_libs/mpi/bin:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/bin:$HPC_BASE/compilers/bin:$HPC_BASE/compilers/compilers/extras:$PATH"
export LD_LIBRARY_PATH="$HPC_BASE/compilers/extras/qd/lib:$HPC_BASE/cuda/$CUDA_VER/targets/x86_64-linux/lib:$HPC_BASE/comm_libs/$CUDA_VER/openmpi4/openmpi-4.1.5/lib:$LD_LIBRARY_PATH"
export MANPATH="$HPC_BASE/compilers/man:$HPC_BASE/comm_libs/mpi/man:$MANPATH"
export CPPFLAGS="-I$HPC_BASE/cuda/$CUDA_VER/include"
```

### 4. Download Quantum ESPRESSO
```bash
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/dc93af13-2b3f-40c3-a41b-2bc05a707a80/intel-onemkl-2025.1.0.803.sh
tar xpzf qe-7.4.1-ReleasePack.tar.gz
```

### 5. Install Intel MKL (2025.1)
Requires manual download or change the link to match your environment.
```bash
chmod +x ./intel-onemkl-2025.1.0.803.sh
./intel-onemkl-2025.1.0.803.sh -a -s --eula accept --install-dir /opt/intel
```

### 6. Set MKL Environment Variables
Export all necessary paths for MKL libraries and headers.
```bash
export MKLROOT="/opt/intel/mkl/2025.1"
export PATH="$MKLROOT/bin:$PATH"
export LD_LIBRARY_PATH="$MKLROOT/lib/intel64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$MKLROOT/lib/intel64:$LIBRARY_PATH"
export CPATH="$MKLROOT/include:$CPATH"
```

### 7. Configure QE
```bash
./configure \
  --enable-openmp \
  --with-cuda-mpi=yes \
  --with-cuda-cc=75 \
  --with-cuda-runtime=12.8 \
  BLAS_LIBS="-lmkl_intel_lp64 -lmkl_sequential -lmkl_core" \
  LAPACK_LIBS="-lmkl_intel_lp64 -lmkl_sequential -lmkl_core" \
  SCALAPACK_LIBS="-lmkl_scalapack_lp64 -lmkl_blacs_openmpi_lp64" \
  FFT_LIBS="-lfftw3" \
  FFT_INCLUDE="/usr/include" \
  LIBDIRS="/usr/lib/x86_64-linux-gnu /opt/intel/mkl/2025.1/lib/intel64"
```

### 8. Fix FFTW Detection
Modifies `make.inc` to ensure `-D__FFTW` is defined.
```bash
sed -i 's/^DFLAGS *=/DFLAGS = -D__FFTW /' make.inc
```

### 9. Compile
Builds `pw.x` using all available CPU threads:
```bash
make pw -j$(nproc)
```

### 10. Add Binaries to PATH
```bash
export PATH="/content/qe-7.4.1/bin:$PATH"
```

---

## ✅ Validation

After successful build, test with:
```bash
pw.x -help
```

---

## 🛠 Troubleshooting

| Problem | Fix |
|--------|------|
| `libmkl*.so not found` | Check and export correct `LD_LIBRARY_PATH` |
| `configure` can't find MPI | Check if HPC SDK MPI is in `PATH` |
| `fftw3.h missing` | Install `libfftw3-dev` and check `FFT_INCLUDE` path |
| Permission denied | Use `chmod +x` or `sudo` as needed |
| Make fails | Run `make veryclean` and try again |

---

## 📌 Notes

---
## 📧 Author

**Tahreezz Murdifin**  
📫 [tahriz716@gmail.com](mailto:tahriz716@gmail.com)

---

## 🤝 Contributing

Feel free to open issues or submit pull requests if you improve this setup.


#!/bin/bash

# Quantum ESPRESSO GPU Version Installation Script for Google Colab or Ubuntu
# Tested with: NVIDIA HPC SDK 25.3, CUDA 12.8, OpenMPI 4.1.5, Intel MKL 2025.1, FFTW
# Target GPU: NVIDIA T4 (Compute Capability 7.5)

set -e  # Exit on any error

# Update and install required libraries
echo "Updating package list and installing required libraries..."
sudo apt-get update
sudo apt-get install -y libblas-dev liblapack-dev libfftw3-dev liblapack-doc libfftw3-doc

echo "Step 1: Install NVIDIA HPC SDK"

wget https://developer.download.nvidia.com/hpc-sdk/25.3/nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz

# Extract the SDK
tar xpzf nvhpc_2025_253_Linux_x86_64_cuda_12.8.tar.gz
cd nvhpc_2025_253_Linux_x86_64_cuda_12.8

# Install with default options (3 for accept + silent install)
printf "\n3\n\n" | ./install

# Set environment variables for HPC SDK
HPC_BASE="/opt/nvidia/hpc_sdk/Linux_x86_64/25.3"
CUDA_VER="12.8"

export PATH="$HPC_BASE/comm_libs/mpi/bin:$HPC_BASE/comm_libs/${CUDA_VER}/openmpi4/openmpi-4.1.5/bin:$HPC_BASE/compilers/bin:$HPC_BASE/compilers/compilers/extras:$PATH"
export LD_LIBRARY_PATH="$HPC_BASE/compilers/extras/qd/lib:$HPC_BASE/cuda/${CUDA_VER}/targets/x86_64-linux/lib:$HPC_BASE/comm_libs/${CUDA_VER}/openmpi4/openmpi-4.1.5/lib:$LD_LIBRARY_PATH"
export MANPATH="$HPC_BASE/compilers/man:$HPC_BASE/comm_libs/mpi/man:$MANPATH"
export CPPFLAGS="-I$HPC_BASE/cuda/${CUDA_VER}/include"

# Go back to root directory
cd /content || cd ~

echo "Step 2: Download and install Quantum ESPRESSO 7.4.1"
wget https://www.quantum-espresso.org/rdm-download/488/v7-4-1/b9b1bb4c233798e6745b13eb56a52ade/qe-7.4.1-ReleasePack.tar.gz

tar xpzf qe-7.4.1-ReleasePack.tar.gz

echo "Step 3: Install Intel MKL (online version)"
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/dc93af13-2b3f-40c3-a41b-2bc05a707a80/intel-onemkl-2025.1.0.803.sh
chmod +x ./intel-onemkl-2025.1.0.803.sh
./intel-onemkl-2025.1.0.803.sh -a -s --eula accept --install-dir /opt/intel

# Set MKL environment variables
MKL_PATH="/opt/intel/mkl/2025.1"

export PATH="$MKL_PATH/bin:$PATH"
export LD_LIBRARY_PATH="$MKL_PATH/lib/intel64:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$MKL_PATH/lib/intel64:$LIBRARY_PATH"
export CPATH="$MKL_PATH/include:$CPATH"

echo "Step 4: Build Quantum ESPRESSO"
cd /content/qe-7.4.1 || cd ~/qe-7.4.1
make veryclean

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
  LIBDIRS="/usr/lib/x86_64-linux-gnu /opt/intel/mkl/2025.1/lib/intel64" || { echo "Failed to configure Quantum ESPRESSO."; exit 1; }

# Ensure FFTW usage is defined
sed -i 's/^DFLAGS *=/DFLAGS = -D__FFTW /' make.inc

echo "Step 5: Compiling pw.x (main DFT code)"
make pw -j$(nproc) || { echo "Failed to compile Quantum ESPRESSO."; exit 1; }

# Add QE binaries to path
export PATH="/content/qe-7.4.1/bin:$PATH"

# Done!
echo "\nQuantum ESPRESSO GPU installation complete. You can now run pw.x or other binaries from /content/qe-7.4.1/bin"

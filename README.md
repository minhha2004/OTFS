# OTFS-IM Simulation Framework

A MATLAB-based simulation framework for evaluating Orthogonal Time Frequency Space with Index Modulation (OTFS-IM) systems over doubly dispersive wireless channels.

The project implements an OTFS physical-layer transceiver pipeline with BER and spectral efficiency analysis under high-mobility channel conditions. The receiver includes Message Passing (MP)-based detection and pattern selection strategies for improving index detection performance.

---

## Key Features

* **Advanced Transceiver Pipeline:** Full implementation of SFFT/ISFFT block processing for Delay-Doppler (DD) and Time-Frequency (TF) grid mappings.
* **Localized Index Modulation (OTFS-IM):** Supports flexible (n, k) sub-block configurations (e.g., n=6, k=3) with dynamic power scaling to preserve energy balance.
* **Heuristic Pattern Selection:** Implements sophisticated Hamming-distance metric tables to choose optimal active sub-carrier activation patterns.
* **Enhanced Message Passing Detector:** Features a customized MP detector backend operating with explicit paper-grade channel normalization.
* **True LLR with Reliability Biasing:** Leverages a weighted log-MAP scoring algorithm (with active hypothesis scaling) to drastically suppress index estimation errors at high SNR.
* **Automated Analytical Visualization:** Built-in benchmarking engine comparing Baseline OTFS vs. OTFS-IM Total, Index, and Symbol error boundaries with automated MATLAB figure plotting.

---

## System Model & Core Dependencies

### Simulation Stack (MATLAB Environment)
* **MATLAB Core Engine:** Recommended version R2022a or newer (requires Communication Toolbox).
* **qammod / qamdemod:** Configured with explicit 'UnitAveragePower', true to maintain strict paper-grade mathematical consistency.

### Repository Component Structure
* **OTFS_sample_code.m:** The core simulation wrapper handling parameters initialization, SNR loops, and main execution blocks.
* **OTFS_channel_gen.m:** High-mobility channel generator computing severe Doppler shifts and multi-path delay profiles.
* **OTFS_channel_output.m:** Simulates physical channel interaction by applying time-varying fading taps and AWGN noise power.
* **OTFS_modulation.m / OTFS_demodulation.m:** Core mod/demod blocks executing Heisenberg and Wigner-Ville transforms.
* **OTFS_mp_detector.m:** Iterative Message Passing signal estimation engine calculating probability convergence grids.
* **UAMP.m:** Unitary Approximate Message Passing alternative implementation for performance comparisons.

---

## System Parameters Setup (Baseline Configuration)

The simulation framework initializes with the following default parameters in OTFS_sample_code.m:

| Parameter | Symbol | Default Value | Description |
| :--- | :--- | :--- | :--- |
| **Doppler Bins** | N | 10 | Number of bins in Doppler domain |
| **Delay Bins** | M | 12 | Number of bins in Delay domain |
| **Simulated Frames**| N_fram | 500 | Total Monte Carlo simulation blocks |
| **SNR Range** | EbN0_dB| 5:5:30 dB | Evaluated signal-to-noise ratios |
| **IM Sub-block Size**| n | 6 | Total sub-carriers per localized block |
| **Active Carriers** | k | 3 | Activated sub-carriers per block (b1 = 4 bits) |
| **Modulation Order** | M_mod | 4 | 4-QAM / QPSK constellation deployment |


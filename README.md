# OTFS System Model

This repository contains a MATLAB simulation of an Orthogonal Time Frequency
Space (OTFS) communication system operating on a delay-Doppler grid.

The current model uses:

- A `10 x 12` delay-Doppler grid (`120` resource elements).
- QPSK modulation for the baseline OTFS system.
- A sparse multipath delay-Doppler channel.
- Cyclic-prefix transmission with complex AWGN.
- OTFS modulation using the ISFFT and Heisenberg transform.
- OTFS demodulation using the Wigner transform and SFFT.
- Message-passing symbol detection at the receiver.
- BER evaluation over `Eb/N0 = 0:5:20 dB`.

## System Flow

```text
Input bits
   -> QPSK mapping on the delay-Doppler grid
   -> OTFS modulation
   -> Delay-Doppler channel and AWGN
   -> OTFS demodulation
   -> Message-passing detection
   -> Detected bits
   -> BER calculation
```

## Run

Open MATLAB in the repository directory and run:

```matlab
OTFS_sample_code
```

The simulation prints the BER results and saves the generated data and figure
in the `results/` directory.

> This README is a temporary overview of the OTFS model and will be expanded
> later.

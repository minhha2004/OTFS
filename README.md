# Full-Grid OTFS-IM Simulation

MATLAB simulation for a full-grid OTFS index-modulation (OTFS-IM) system.
The current work replaces the earlier block-wise OHD architecture with one
activation pattern over the complete delay-Doppler grid.

## Current System

- Delay-Doppler grid: `N = 10`, `M = 12`, hence `Ngrid = 120`.
- Baseline: conventional OTFS with 16-QAM on all 120 positions.
- OTFS-IM: 16-QAM with `K = 113` active positions.
- Index mapping: NBC combinatorial rank/unrank; no activation-pattern LUT is
  stored.
- Receiver: MP detector returns a soft probability for every 16-QAM symbol
  and zero. The receiver sums the 16 nonzero probabilities and selects the
  `K` largest values (Top-K).
- Local support refinement / two-swap is disabled in the current main result,
  so the baseline OTFS-IM receiver is MP + Top-K only.

## Main Simulation

Run the BER comparison:

```matlab
OTFS_sample_code
```

The script compares OTFS-16QAM with OTFS-IM NBC, prints BER information, and
saves `.mat`, `.txt`, and `.png` outputs in `results/`.

## Current Formula-Validation Work

The performance-analysis model is built **after MP**, not from the raw OTFS
interference. For each position, the remaining MP error is represented by a
Bernoulli-Gaussian model with separately estimated active and inactive
parameters:

- Active: `p_A`, `nu_A`
- Inactive: `p_0`, `nu_0`

`run_mp_pattern_formula_validation.m` directly validates the final pattern
error expression in the current derivation:

1. Simulate the OTFS-IM receiver and measure its Top-K pattern-error rate.
2. Estimate the Bernoulli-Gaussian parameters from the soft MP output.
3. Numerically construct `F_X` and `F_Z` from the Bernoulli-Gaussian model.
4. Evaluate the final pattern-error formula and compare it with simulation.

Recommended high-SNR run:

```matlab
run_mp_pattern_formula_validation(5000, [20 25 30])
```

The validation result must still be assessed. Earlier diagnostic tests showed
that MP outputs in the same frame can be correlated, so the independence
assumption in the final formula is an approximation that requires discussion
with the mentor.

## Important Files

```text
OTFS_sample_code.m                         Main BER simulation entry point
run_mp_pattern_formula_validation.m        Direct validation of the BG formula
config/config_full_grid_otfs_im.m          Shared parameters
config/build_full_grid_variant.m            Rate, power, and noise setup
simulation/simulate_baseline_otfs.m         Conventional OTFS-16QAM branch
simulation/simulate_full_grid_otfs_im.m     Full-grid OTFS-IM transmitter/receiver
OTFS_mp_detector.m                          MP soft-output detector
utils/combination_rank_bits.m               Pattern -> NBC index bits
utils/combination_unrank_bits.m             NBC index bits -> pattern
utils/build_binomial_bit_table.m            Binomial coefficients only, not a LUT
```

## Requirements

MATLAB with Communications Toolbox is required (`qammod`, `qamdemod`,
`bi2de`, and `de2bi` are used).

# OTFS-IM OHD Simulation

MATLAB simulation code for comparing conventional OTFS with OTFS using Index
Modulation (OTFS-IM). The current project state focuses on one final method:
OHD-based activation-pattern selection with MP detection and block-wise joint
MAP index/symbol decision.

The code is organized so that the main script only connects configuration,
OHD pattern selection, simulation, reporting, and plotting.

---

## Current Experiment

Default configuration is defined in `config/config_otfs_im.m`.

| Parameter | Current value | Description |
| --- | ---: | --- |
| `N` | 10 | Doppler bins |
| `M` | 12 | Delay bins |
| `N_total` | 120 | Total DD resource elements |
| `N_fram` | 1000 | Monte Carlo frames |
| `EbN0_dB` | `5:5:30` | Simulated Eb/N0 range |
| `M_mod_otfs` | 4 | Baseline OTFS QPSK / 4-QAM |
| `n` | 4 | OTFS-IM block size |
| `k` | 3 | Active positions per IM block |
| `M_mod_im` | 4 | Active-symbol QPSK / 4-QAM |
| `se_otfs` | 2.00 | Baseline OTFS spectral efficiency |
| `se_im` | 2.00 | OTFS-IM spectral efficiency for `n=4,k=3` |

With `n=4,k=3`, OTFS-IM has the same spectral efficiency as baseline OTFS:

```text
OTFS SE    = 2.00 bits/symbol
OTFS-IM SE = 2.00 bits/symbol
Reduction  = 0%
```

---

## How To Run

Open MATLAB in the project folder and run:

```matlab
OTFS_sample_code
```

The script will:

1. Load system parameters from `config/config_otfs_im.m`.
2. Select the OHD activation-pattern table.
3. Run baseline OTFS simulation.
4. Run OTFS-IM simulation.
5. Print BER/index/symbol/PER results.
6. Generate report figures.

---

## Project Structure

```text
OTFS_sample_code.m
config/
  config_otfs_im.m
pattern_selection/
  select_patterns_ohd.m
  evaluate_pattern_table.m
simulation/
  simulate_baseline_otfs.m
  simulate_otfs_im.m
reporting/
  print_pattern_info.m
  print_ohd_results.m
  plot_ohd_results.m
utils/
  gray_to_bin_idx.m
OTFS_modulation.m
OTFS_demodulation.m
OTFS_channel_gen.m
OTFS_channel_output.m
OTFS_mp_detector.m
```

### Main Files

- `OTFS_sample_code.m`  
  Main runner. It compares conventional OTFS with OHD-selected OTFS-IM.

- `config/config_otfs_im.m`  
  Stores all simulation parameters, including grid size, frame count, Eb/N0
  range, modulation order, IM block size, spectral efficiency, and noise power.

- `pattern_selection/select_patterns_ohd.m`  
  Deterministically selects the activation-pattern table by maximizing the
  minimum pairwise Hamming distance among selected constant-weight patterns.

- `simulation/simulate_baseline_otfs.m`  
  Runs the conventional OTFS BER simulation.

- `simulation/simulate_otfs_im.m`  
  Runs OTFS-IM BER simulation. The receiver uses MP output probabilities and
  performs block-wise joint MAP decision over valid OHD patterns and QAM symbol
  combinations.

- `reporting/plot_ohd_results.m`  
  Generates BER, error-component, pattern-table, Hamming-matrix, carrier-usage,
  and BER-SE trade-off figures.

---

## Output Figures

The reporting step generates:

- OTFS vs OHD OTFS-IM BER curve
- OTFS-IM total/index/symbol/pattern error curves
- OHD selected pattern table heatmap
- OHD Hamming distance matrix
- Carrier usage bar chart
- BER-SE trade-off at the Eb/N0 point closest to 10 dB

---

## Notes On Randomness

The OHD pattern selection is deterministic.

Randomness is only used for Monte Carlo simulation:

- random information bits,
- random Doppler taps/channel coefficients,
- AWGN noise.

Seeds are fixed in `config/config_otfs_im.m`:

```matlab
cfg.rng_seed = 1;
cfg.rng_seed_baseline = 11;
cfg.rng_seed_im_compare = 22;
```

This keeps repeated runs reproducible unless the configuration is changed.

---

## Requirements

- MATLAB
- Communications Toolbox for `qammod`, `qamdemod`, `bi2de`, and `de2bi`


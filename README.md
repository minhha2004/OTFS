# OTFS-IM Pattern-Selection Simulation

MATLAB simulation code for comparing conventional OTFS with OTFS using Index
Modulation (OTFS-IM). The current project state compares OFDM, OTFS, and three
OTFS-IM pattern-table choices:

- OHD activation-pattern selection,
- Balanced-OHD (B-OHD) activation-pattern selection,
- optional random-pattern baseline for diagnostic comparison.

The receiver uses MP output probabilities followed by a block-wise joint MAP
index/symbol decision.

The code is organized so that the main script only connects configuration,
pattern selection, simulation, reporting, and plotting.

---

## Current Experiment

Default configuration is defined in `config/config_otfs_im.m`.

| Parameter | Current value | Description |
| --- | ---: | --- |
| `N` | 10 | Doppler bins |
| `M` | 12 | Delay bins |
| `N_total` | 120 | Total DD resource elements |
| `N_fram` | 2000 | Fixed OTFS/OTFS-IM Monte Carlo frames |
| `N_fram_ofdm` | 1000 | Fixed OFDM frames for the heavier full-frame LMMSE baseline |
| `EbN0_dB` | `5:2:25` | Simulated Eb/N0 range |
| `M_mod_otfs` | 4 | Baseline OTFS QPSK / 4-QAM |
| `n` | 6 | OTFS-IM block size |
| `k` | 5 | Active positions per IM block |
| `M_mod_im` | 4 | Active-symbol QPSK / 4-QAM |
| `se_otfs` | 2.00 | Baseline OTFS spectral efficiency |
| `se_im` | 2.00 | OTFS-IM spectral efficiency for `n=6,k=5` |

Random-pattern comparison can be enabled/disabled in the same config file:

```matlab
cfg.enable_random_compare = true;
cfg.num_random_tables = 5;
cfg.N_fram_random = 200;
cfg.use_adaptive_frames = false;
cfg.apply_display_error_floor = false;
```

With the current `n=6,k=5` setting, OTFS-IM has the same spectral efficiency
as baseline OTFS:

```text
OTFS SE    = 2.00 bits/symbol
OTFS-IM SE = 2.00 bits/symbol
Reduction  = 0%
```

Note: exact OHD search becomes combinatorially large for some configurations,
such as `n=8,k=6`. The OHD selector reports a clear error in that case. B-OHD
keeps the OHD minimum-distance objective and applies deterministic tie-breaking
based on average distance, closest-pair count, and carrier-usage balance.

---

## How To Run

Open MATLAB in the project folder and run:

```matlab
OTFS_sample_code
```

The script will:

1. Load system parameters from `config/config_otfs_im.m`.
2. Select the OHD and B-OHD activation-pattern tables.
3. Run baseline OFDM simulation over the same time-varying channel model.
4. Run baseline OTFS simulation.
5. Run OTFS-IM simulations for both pattern-selection methods.
6. Print BER/index/symbol/PER results, with random baseline when enabled.
7. Generate report figures.
8. Optionally compare OHD with random pattern tables when the current
   `(n,k)` configuration has unused candidate patterns.

---

## Project Structure

```text
OTFS_sample_code.m
config/
  config_otfs_im.m
pattern_selection/
  select_patterns_balanced_ohd.m
  select_patterns_ohd.m
  evaluate_pattern_table.m
simulation/
  simulate_baseline_ofdm.m
  simulate_baseline_otfs.m
  simulate_otfs_im.m
  compare_random_patterns.m
reporting/
  apply_display_error_floor.m
  print_pattern_info.m
  print_pattern_method_results.m
  plot_pattern_method_results.m
  print_ohd_results.m
  plot_ohd_results.m
  save_simulation_results.m
  plot_se_ber_tradeoff_from_results.m
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
  Main runner. It compares conventional OFDM, conventional OTFS, OHD-selected
  OTFS-IM, B-OHD OTFS-IM, and optional random-pattern OTFS-IM.

- `config/config_otfs_im.m`  
  Stores all simulation parameters, including grid size, frame count, Eb/N0
  range, modulation order, IM block size, spectral efficiency, and noise power.

- `pattern_selection/select_patterns_ohd.m`  
  Deterministically selects the activation-pattern table by maximizing the
  minimum pairwise Hamming distance among selected constant-weight patterns.

- `pattern_selection/select_patterns_balanced_ohd.m`  
  Balanced-OHD pattern selection. It keeps the OHD minimum-distance objective
  and uses additional deterministic tie-breaking criteria, including average
  distance, closest-pair count, and carrier-usage balance.

- `simulation/simulate_baseline_ofdm.m`  
  Runs the conventional OFDM BER simulation using the same channel model and
  perfect-CSI full-frame TF-domain LMMSE equalization.

- `simulation/simulate_baseline_otfs.m`  
  Runs the conventional OTFS BER simulation.

- `simulation/simulate_otfs_im.m`  
  Runs OTFS-IM BER simulation. The receiver uses MP output probabilities and
  performs block-wise joint MAP decision over valid OHD patterns and QAM symbol
  combinations.

- `simulation/compare_random_patterns.m`  
  Runs a diagnostic random-pattern baseline. This is not part of the proposed
  method; it is used only to check whether the OHD-selected pattern table is
  better than random pattern choices.

- `reporting/print_pattern_method_results.m`  
  Prints OTFS, OHD OTFS-IM, B-OHD OTFS-IM, and optional random OTFS-IM
  comparison tables, including total BER and index/symbol/pattern components.

- `reporting/plot_pattern_method_results.m`  
  Generates report-focused figures: activation pattern, main BER comparison,
  zoomed BER comparison, error decomposition, and pattern geometry.

- `reporting/save_simulation_results.m`  
  Saves the full run to `results/` and updates `results/latest_results.mat`.

- `reporting/plot_se_ber_tradeoff_from_results.m`  
  Builds a spectral-efficiency/BER trade-off plot from multiple saved result
  files when several `(n,k)` configurations have been simulated.

---

## Output Figures

The reporting step generates:

- OTFS-IM activation-pattern illustration
- BER overview, 0-20 dB: OFDM, OTFS, OHD OTFS-IM, B-OHD OTFS-IM
- Zoomed BER, 5-20 dB: OTFS, OHD OTFS-IM, B-OHD OTFS-IM
- Error decomposition, 5-20 dB: index BER, symbol BER, pattern error rate
- OHD pattern geometry: activation-table heatmap, Hamming matrix, carrier usage
- Spectral-efficiency summary: SE bar chart and BER-SE point comparison
- Optional random-pattern validation, 5-20 dB, shown only when the selected
  `(n,k)` configuration has unused candidate patterns.

The main script also saves:

```text
results/latest_results.mat
results/otfs_im_n< n >_k< k >_<timestamp>.mat
```

When `cfg.apply_display_error_floor` is enabled, zero-error points are displayed
using the Monte Carlo resolution, such as `1/(number of simulated bits)`. This
keeps semilog BER curves finite without claiming that the true BER is exactly
that value.

---

## Notes On Randomness

B-OHD and OHD pattern selection are deterministic.

For large `(n,k)` values, exact OHD selection may become combinatorially too
large. The selector includes a guard and will report a clear error instead of
letting MATLAB allocate a huge `nchoosek` matrix.

Randomness is only used for Monte Carlo simulation:

- random information bits,
- random Doppler taps/channel coefficients,
- AWGN noise.
- optional random-pattern baseline tables.

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

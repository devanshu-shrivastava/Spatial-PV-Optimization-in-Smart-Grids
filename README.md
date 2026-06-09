# Simulation-Based Spatial Optimisation of Solar PV for Loss Minimisation in Smart Grid Distribution Systems

**Course:** Smart Grids — Rutgers University, New Brunswick  
**Instructor:** Prof. Amin Mahmoud  
**Author:** Devanshu Shrivastava  

---

## Overview

Distribution networks lose between 5–13% of power as heat, and nearly 70% of total grid losses occur at the distribution level. As solar PV adoption grows rapidly, panels are often installed without spatial optimisation — leading to reverse power flows, voltage fluctuations, and increased losses.

This project addresses a core question:

> **Where should Solar PV be placed, and at what capacity, to minimise active power losses in a distribution network?**

Two approaches are compared: a **Spatial Sweep** (brute-force sequential placement) and **Particle Swarm Optimisation (PSO)** for joint location and sizing optimisation.

---

## Network Model

The IEEE 33-Bus Radial Distribution System was used as the test network.

| Parameter | Value |
|-----------|-------|
| Buses | 33 |
| Lines | 32 |
| Base Voltage | 12.66 kV |
| Total Active Load | 3.715 MW |
| Total Reactive Load | 2.300 MVAR |
| Baseline Active Power Loss | 202 kW |

**Network Topology:**
- Main Feeder: Bus 1 → 2 → 3 → ... → 18
- Lateral 1: Bus 2 → 19 → 20 → 21 → 22
- Lateral 2: Bus 3 → 23 → 24 → 25
- Lateral 3: Bus 6 → 26 → 27 → ... → 33 (heaviest loaded)
- Bus 1 (Substation) is the Slack Bus — voltage fixed at 1.0 pu

---

## Methodology

### Step 1 — Network Setup
IEEE 33-bus line data loaded in MATLAB — resistance, reactance, and load at each bus.

### Step 2 — Power Flow (DistFlow)
Backward/Forward Sweep using Baran & Wu DistFlow equations to solve voltage profiles and compute baseline losses.

### Step 3 — PV Modelling
Solar PV modelled as a negative load (power injection) at candidate buses. Reactive power set to zero (unity power factor).

### Step 4 — Spatial Sweep
A fixed 1 MW PV unit placed sequentially at each bus (2–33). Power flow re-run and losses recorded per location.

### Step 5 — PSO Optimisation
A swarm of 30 particles simultaneously optimises both bus location (2–33) and PV size (100–3000 kW) over 100 iterations.

**PSO Velocity Update Equation:**
```
v = w·v + c₁·r₁·(personal_best − position) + c₂·r₂·(global_best − position)
```

| PSO Parameter | Value |
|---------------|-------|
| Particles | 30 |
| Iterations | 100 |
| Bus Search Space | 2 – 33 |
| PV Size Search Space | 100 – 3000 kW |

---

## Results

### Power Loss Comparison

| Scenario | Active Power Loss | Loss Reduction |
|----------|------------------|----------------|
| Baseline (No PV) | 197.9 kW | — |
| Spatial Sweep (Bus 30, 1 MW) | 125.3 kW | 36.7% |
| PSO Optimised (Bus 6, 2.56 MW) | 102.8 kW | **48.0%** |

### Voltage Profile
- Baseline dips to **0.917 pu** — violates IEEE 0.95 pu limit at 12 buses
- Spatial Sweep improves the main feeder but lateral violations remain
- PSO profile stays above 0.95 pu across most of the network
- PSO reduces voltage violations from 14 buses to near zero

### PSO Sensitivity Analysis (6 Independent Runs)

| Run | Optimal Bus | PV Size (kW) | Loss (kW) | Reduction |
|-----|-------------|--------------|-----------|-----------|
| 1 | Bus 26 | 2422.76 | 104.67 | 47.12% |
| 2 | Bus 6 | 2561.54 | 102.84 | 48.04% |
| 3 | Bus 6 | 2561.54 | 102.84 | 48.04% |
| 4 | Bus 26 | 2422.76 | 104.67 | 47.12% |
| 5 | Bus 6 | 2561.54 | 102.84 | 48.04% |
| 6 | Bus 6 | 2561.54 | 102.84 | 48.04% |

**Mean Loss:** 103.45 kW | **Std Deviation:** 0.94 kW | **Best Loss:** 102.84 kW

Low standard deviation confirms PSO reliably converges despite random initialisation.

---

## Key Findings

- **47.1% loss reduction** achieved with PSO-optimised placement at Bus 6 (2.56 MW)
- **Voltage violations resolved** — baseline had 14 buses below 0.95 pu; PSO brings network close to full compliance
- **Location matters more than size** — placement at feeder branch entry points (Bus 6, Bus 26) outperforms deep-network placement regardless of capacity
- **PSO is robust** — 6 independent runs yield std deviation of only 0.94 kW

---

## Tools Used

- MATLAB (Power flow simulation, PSO implementation)
- DistFlow equations (Baran & Wu)
- IEEE 33-Bus standard test system

---

## Future Work

- Multi-unit PV placement across multiple buses simultaneously
- Battery storage integration alongside PV
- Dynamic load profiles (time-varying demand)
- Reactive power support from PV inverters

---

## Repository Contents

| File | Description |
|------|-------------|
| `main.m` | Main script — runs spatial sweep and PSO |
| `distflow.m` | Power flow solver (DistFlow) |
| `pso_optimise.m` | PSO algorithm implementation |
| `ieee33_data.m` | IEEE 33-bus network data |
| `README.md` | This file |

> **Note:** Update the file table above to match your actual MATLAB filenames before uploading.

---

## Author

**Devanshu Shrivastava**  
MEng Energy Systems, Rutgers University  
[linkedin.com/in/shrivastavadevanshu](https://linkedin.com/in/shrivastavadevanshu)  
devanshushrivastava28@gmail.com

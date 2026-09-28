# Diagrams

## Inputs

DAWO-Core is the upstream flake for all downstreams. One can directly input DAWO-Core or have a intermediary organisation do it for you.

```mermaid

flowchart RL

DO[Downstream Org]
DC[DAWO-Core]
INT[Intermediary Org]
SUB[Subsidiary Org]

SUB -->|Flake input| INT
INT -->|Flake input| DC
DO -->|Flake input| DC

```

## Options

All DAWO options are categorised in the following three categories:

- Mandatory
- Opt-Out
- Opt-In

```mermaid
flowchart LR

subgraph "Opt-In (Could-Have)"
    GNM[Other Desktops]
    CMPL[Complicated Packages made easy]
end

subgraph "Opt-Out (Should-Have)"
    SD[Sane Defaults]
    Sec[Security Measures that make sense for most]
    DSK[Default Desktop]
end

subgraph "Mandatory (Must-Have)"
    S["Security Baselines (based in Laws and Regulations)"]
    H[Minimal Hardening Measures]
    MVP[Minimal config to make DAWO functional]
end


```



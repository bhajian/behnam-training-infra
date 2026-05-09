# Grafana DCGM Dashboard

GPU monitoring dashboard for the Soperator cluster. Connects to the VictoriaMetrics instance deployed by the Soperator telemetry stack.

## Deploy

```bash
kubectl apply -k dashboards/
```

## Access

```bash
kubectl port-forward svc/grafana -n monitoring-system 3000:3000
```

Open http://localhost:3000 (anonymous viewer access enabled, admin password: `admin`).

## Panels

- GPU Utilization (%)
- GPU Memory Used (MiB)
- Tensor Core Active (%)
- Memory Copy Utilization (%)
- GPU Temperature (C) with thresholds
- Power Usage (W)
- SM Clock (MHz)
- PCIe TX/RX Throughput (bytes/s)

Filter by pod, GPU index, or HPC job ID using the dropdown variables.

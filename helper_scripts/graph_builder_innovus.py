import csv
import os
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict

# --- Configuration ---
csv_file = "CSVs/layout_TL_results.csv"
output_slack_img = "CSVs/layout_metrics_slack_bar.png"
output_power_img = "CSVs/layout_metrics_power_3d.png"

# --- IEEE rcParams Configuration ---
plt.rcParams.update({
    'font.family': 'serif',
    'font.serif': ['Times New Roman', 'Times', 'DejaVu Serif'],
    'font.size': 10,
    'axes.labelsize': 10,
    'axes.titlesize': 10,
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    'legend.fontsize': 8,
    'legend.framealpha': 1.0,
    'legend.edgecolor': 'black',
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.05
})

def main():
    if not os.path.isfile(csv_file):
        print(f"Error: Could not find {csv_file}.")
        return

    # Data structures
    setup_slacks = {}
    hold_slacks = {}
    power_data = defaultdict(lambda: defaultdict(dict))

    with open(csv_file, mode='r') as file:
        reader = csv.reader(file)
        try:
            headers = next(reader)
        except StopIteration:
            return

        idx_freq = headers.index("freq MHz (clk)")
        idx_setup = headers.index("Setup Slack (ns)")
        idx_hold = headers.index("Hold Slack (ns)")
        idx_time = headers.index("Simulation Time (ns)")
        idx_leakage = headers.index("Leakage Power (uW)")
        idx_total = headers.index("Total Power (uW)")
        idx_dynamic = headers.index("Dynamic Power (uW)")

        for row in reader:
            if not row or len(row) <= max(idx_freq, idx_setup, idx_hold, idx_dynamic):
                continue
            try:
                freq = round(float(row[idx_freq]), 1)
                
                # Extract Timing
                if row[idx_setup] != "N/A" and freq not in setup_slacks:
                    setup_slacks[freq] = float(row[idx_setup])
                if row[idx_hold] != "N/A" and freq not in hold_slacks:
                    hold_slacks[freq] = float(row[idx_hold])

                # Extract Power
                time_val = float(row[idx_time]) if row[idx_time] != "N/A" else 0.0
                if row[idx_leakage] != "N/A" and row[idx_dynamic] != "N/A" and row[idx_total] != "N/A":
                    power_data[freq][time_val] = {
                        'Leakage': float(row[idx_leakage]),
                        'Dynamic': float(row[idx_dynamic]),
                        'Total': float(row[idx_total])
                    }
            except ValueError:
                continue

    freqs = sorted(list(power_data.keys()))
    if not freqs:
        print("No valid data found to plot.")
        return

    print("Generating discrete bar charts...")

    # ==========================================
    # 1. Timing Slack Plot (2D Grouped Bar Chart with Zoom)
    # ==========================================
    fig, ax = plt.subplots(figsize=(5.0, 3.0))
    
    x_indices = np.arange(len(freqs))
    width = 0.35
    
    s_vals = [setup_slacks.get(f, 0) for f in freqs]
    h_vals = [hold_slacks.get(f, 0) for f in freqs]
    
    # Main Bars
    ax.bar(x_indices - width/2, s_vals, width, label='Setup Slack', color='tab:red', alpha=0.85, edgecolor='black')
    ax.bar(x_indices + width/2, h_vals, width, label='Hold Slack', color='tab:orange', alpha=0.85, edgecolor='black')
    
    ax.axhline(0, color='k', linestyle=':', linewidth=1.0)
    ax.set_xticks(x_indices)
    ax.set_xticklabels([f"{f} MHz" for f in freqs])
    ax.set_ylabel('Timing Slack (ns)')
    ax.legend(loc='upper right')
    ax.grid(True, linestyle=':', alpha=0.5, axis='y')

    # Add Inset Zoom for the highest frequency
    if len(freqs) > 1:
        target_idx = len(freqs) - 1  # Grabs the last index (e.g., 371 MHz)
        target_freq = freqs[target_idx]

        # Position inset: [x0, y0, width, height] in axes coordinates
        # Centered somewhat in the empty space between the large 10MHz bar and the right edge
        axins = ax.inset_axes([0.45, 0.40, 0.45, 0.45])

        # Plot just the target bars inside the inset
        axins.bar(target_idx - width/2, s_vals[target_idx], width, color='tab:red', alpha=0.85, edgecolor='black')
        axins.bar(target_idx + width/2, h_vals[target_idx], width, color='tab:orange', alpha=0.85, edgecolor='black')

        # Formatting the inset
        axins.axhline(0, color='k', linestyle=':', linewidth=1.0)
        axins.set_xlim(target_idx - width - 0.1, target_idx + width + 0.1)

        # Dynamically set Y limits tightly around the micro-values
        y_min = min(0, s_vals[target_idx], h_vals[target_idx])
        y_max = max(0, s_vals[target_idx], h_vals[target_idx])
        y_margin = max((y_max - y_min) * 0.5, 0.005) # Ensures at least a 5ps visual margin
        
        axins.set_ylim(y_min - y_margin, y_max + y_margin)
        axins.set_xticks([target_idx])
        axins.set_xticklabels([f"{target_freq} Zoom"])
        axins.tick_params(labelsize=8)
        axins.grid(True, linestyle=':', alpha=0.5, axis='y')

        # Draw the zoom lines connecting to the main plot
        ax.indicate_inset_zoom(axins, edgecolor="black")
    
    fig.savefig(output_slack_img)
    plt.close(fig)
    print(f"Saved {output_slack_img}")

    # ==========================================
    # 2. Total Power Plot (3D Bar Chart)
    # ==========================================
    fig = plt.figure(figsize=(6.0, 5.0))

    metrics = ['Leakage', 'Dynamic', 'Total']
    colors = ['tab:blue', 'tab:orange', 'tab:green']
    y_labels = ['0ns', 'X', '2X']

    bar_width = 0.4
    bar_depth = 0.4

    for i, freq in enumerate(freqs):
        ax = fig.add_subplot(1, len(freqs), i + 1, projection='3d')
        ax.set_title(f"{freq} MHz\n", fontweight='bold')

        runtimes = sorted(list(power_data[freq].keys()))
        
        for y_idx, rt in enumerate(runtimes):
            if y_idx > 2: break 
            
            data = power_data[freq][rt]
            
            for x_idx, metric in enumerate(metrics):
                z_val = data[metric]
                
                x_pos = x_idx - (bar_width / 2)
                y_pos = y_idx - (bar_depth / 2)
                
                label = metric if (i == 0 and y_idx == 0) else ""
                
                ax.bar3d(x_pos, y_pos, 0, 
                         bar_width, bar_depth, z_val, 
                         color=colors[x_idx], alpha=0.9, edgecolor='black', linewidth=0.5, label=label)

        ax.set_xticks(np.arange(len(metrics)))
        ax.set_xticklabels(metrics)
        
        ax.set_yticks(np.arange(len(y_labels)))
        ax.set_yticklabels(y_labels)
        
        ax.set_zlabel('\nPower (uW)')
        
        ax.view_init(elev=20, azim=105)
        ax.tick_params(axis='x', pad=0)
        ax.tick_params(axis='y', pad=0)
        ax.tick_params(axis='z', pad=5)

    handles, labels = fig.axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc='upper center', bbox_to_anchor=(0.5, 0.85), ncol=3)

    plt.subplots_adjust(wspace=0.3, top=0.85, bottom=0.1, left=0.05, right=0.95)
    
    fig.savefig(output_power_img)
    plt.close(fig)
    print(f"Saved {output_power_img}")

if __name__ == "__main__":
    main()
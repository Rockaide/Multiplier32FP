import csv
import os
import matplotlib.pyplot as plt
from collections import defaultdict

# --- Configuration ---
csv_file = "CSVs/TL_results.csv"
output_area_img = "CSVs/metrics_area.png"
output_slack_img = "CSVs/metrics_slack.png"
output_power_img = "CSVs/metrics_power.png"

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
    'figure.figsize': (3.5, 2.5),  # 3.5 inches wide for IEEE single-column
    'lines.linewidth': 1.0,
    'lines.markersize': 4,
    'axes.grid': True,
    'grid.alpha': 0.5,
    'grid.linestyle': ':',
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.05
})

def main():
    if not os.path.isfile(csv_file):
        print(f"Error: Could not find {csv_file}. Please ensure the extraction script has run.")
        return

    areas = defaultdict(list)
    slacks = defaultdict(list)
    powers = defaultdict(list)

    print(f"Reading data from {csv_file}...")

    with open(csv_file, mode='r') as file:
        reader = csv.reader(file)
        
        try:
            headers = next(reader)
        except StopIteration:
            print("Error: CSV file is empty.")
            return

        try:
            idx_freq = headers.index("freq MHz (clk)")
            idx_area = headers.index("total um2")
            idx_slack = headers.index("timing slack ps")
            idx_power = headers.index("total (W)")
        except ValueError as e:
            print(f"Error mapping headers: {e}. Check if CSV header names match exactly.")
            return

        for row in reader:
            if not row or len(row) <= max(idx_freq, idx_area, idx_slack, idx_power):
                continue
                
            try:
                freq = float(row[idx_freq])
                
                if row[idx_area] != "N/A":
                    areas[freq].append(float(row[idx_area]))
                if row[idx_slack] != "N/A":
                    slacks[freq].append(float(row[idx_slack]))
                if row[idx_power] != "N/A":
                    powers[freq].append(float(row[idx_power]))
            except ValueError:
                continue

    sorted_freqs = sorted(list(set(list(areas.keys()) + list(slacks.keys()) + list(powers.keys()))))

    plot_freqs = []
    avg_areas = []
    avg_slacks = []
    avg_powers = []

    for f in sorted_freqs:
        plot_freqs.append(f)
        avg_areas.append(sum(areas[f])/len(areas[f]) if f in areas and areas[f] else None)
        avg_slacks.append(sum(slacks[f])/len(slacks[f]) if f in slacks and slacks[f] else None)
        avg_powers.append(sum(powers[f])/len(powers[f]) if f in powers and powers[f] else None)

    max_freq_zero_slack = None
    valid_slacks = [(f, s) for f, s in zip(plot_freqs, avg_slacks) if s is not None]
    
    positive_slacks = [f for f, s in valid_slacks if s >= 0]
    if positive_slacks:
        max_freq_zero_slack = max(positive_slacks)

    print("Generating IEEE formatted plots...")

    # ==========================================
    # 1. Total Area Plot (Solid Line, Circles)
    # ==========================================
    fig, ax = plt.subplots()
    ax.plot(plot_freqs, avg_areas, marker='o', color='k', linestyle='-', label='Total Area')
            
    if max_freq_zero_slack is not None:
        ax.axvline(x=max_freq_zero_slack, color='k', linestyle='--', linewidth=1.0, 
                    label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
        ax.legend()
        
    ax.set_xlabel('Frequency (MHz)')
    ax.set_ylabel('Total Area (um²)')
    fig.savefig(output_area_img)
    plt.close(fig)
    print(f"Saved {output_area_img}")

    # ==========================================
    # 2. Timing Slack Plot (Dashed Line, Squares)
    # ==========================================
    fig, ax = plt.subplots()
    ax.plot(plot_freqs, avg_slacks, marker='s', color='k', linestyle='--', label='Timing Slack')
            
    ax.axhline(0, color='k', linestyle=':', linewidth=1.0)
    
    if max_freq_zero_slack is not None:
        ax.axvline(x=max_freq_zero_slack, color='k', linestyle='-.', linewidth=1.0, 
                    label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
                    
    ax.legend()
    ax.set_xlabel('Frequency (MHz)')
    ax.set_ylabel('Timing Slack (ps)')
    fig.savefig(output_slack_img)
    plt.close(fig)
    print(f"Saved {output_slack_img}")

    # ==========================================
    # 3. Total Power Plot (Dotted Line, Triangles)
    # ==========================================
    fig, ax = plt.subplots()
    ax.plot(plot_freqs, avg_powers, marker='^', color='k', linestyle=':', label='Total Power')
            
    if max_freq_zero_slack is not None:
        ax.axvline(x=max_freq_zero_slack, color='k', linestyle='--', linewidth=1.0, 
                    label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
        ax.legend()
        
    ax.set_xlabel('Frequency (MHz)')
    ax.set_ylabel('Total Power (W)')
    fig.savefig(output_power_img)
    plt.close(fig)
    print(f"Saved {output_power_img}")

if __name__ == "__main__":
    main()
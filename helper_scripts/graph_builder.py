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
    'figure.figsize': (5.0, 3.0),  
    'lines.linewidth': 1.2,        
    'lines.markersize': 3,         
    'axes.grid': True,
    'grid.alpha': 0.5,
    'grid.linestyle': ':',
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'savefig.pad_inches': 0.05
})

def extract_valid_data(x_list, y_list):
    """Filters out None values to prevent Matplotlib plotting errors"""
    filtered = [(x, y) for x, y in zip(x_list, y_list) if (y is not None and x != 10)]
    if not filtered:
        return [], []
    return zip(*filtered)

def add_inset_zoom(ax, x_val, y_val, x_lims, marker, color, ref_x=None, loc=[0.55, 0.55, 0.4, 0.4]):
    """Creates a zoomed-in inset axes for a specific region of data."""
    axins = ax.inset_axes(loc)
    axins.plot(x_val, y_val, marker=marker, color=color, linestyle='-', alpha=0.85)
    
    if ref_x is not None:
        # Match line styles to the main plots depending on the metric
        line_style = '-.' if 'tab:red' in color else '--'
        axins.axvline(x=ref_x, color='k', linestyle=line_style, linewidth=1.0)
        
    if 'tab:red' in color: # Explicitly handle the zero line for Slack
        axins.axhline(0, color='k', linestyle=':', linewidth=1.0)
        
    axins.set_xlim(x_lims)
    
    # Dynamically scale the y-axis of the inset based on the data within the x_lims
    inset_y = [y for x, y in zip(x_val, y_val) if x_lims[0] <= x <= x_lims[1]]
    if inset_y:
        y_margin = (max(inset_y) - min(inset_y)) * 0.5
        y_margin = max(y_margin, 5) # Ensure at least some vertical margin
        axins.set_ylim(min(inset_y) - y_margin, max(inset_y) + y_margin)
        
    axins.grid(True, linestyle=':', alpha=0.5)
    axins.tick_params(labelsize=6)
    
    # Draw the lines connecting the inset box to the original data
    ax.indicate_inset_zoom(axins, edgecolor="black")
    return axins

def main():
    if not os.path.isfile(csv_file):
        print(f"Error: Could not find {csv_file}.")
        return

    areas = defaultdict(list)
    slacks = defaultdict(list)
    powers = defaultdict(list)

    with open(csv_file, mode='r') as file:
        reader = csv.reader(file)
        try:
            headers = next(reader)
        except StopIteration:
            return

        idx_freq = headers.index("freq MHz (clk)")
        idx_area = headers.index("total um2")
        idx_slack = headers.index("timing slack ps")
        idx_power = headers.index("total (W)")

        for row in reader:
            if not row or len(row) <= max(idx_freq, idx_area, idx_slack, idx_power):
                continue
            try:
                freq = round(float(row[idx_freq]), 1) 
                
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
    # 1. Total Area Plot 
    # ==========================================
    fig, ax = plt.subplots()
    x_val, y_val = extract_valid_data(plot_freqs, avg_areas)
    
    if x_val and y_val:
        ax.plot(x_val, y_val, marker='o', color='tab:blue', linestyle='-', alpha=0.85, label='Total Area')
                
        if max_freq_zero_slack is not None:
            ax.axvline(x=max_freq_zero_slack, color='k', linestyle='--', linewidth=1.0, 
                        label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
        
        ax.legend()
        
        # Inset zoom logic (Placed top-left since area data goes up and right)
        add_inset_zoom(ax, x_val, y_val, [360, 375], 'o', 'tab:blue', max_freq_zero_slack, loc=[0.6, 0.25, 0.35, 0.35])

        ax.set_xlabel('Frequency (MHz)')
        ax.set_ylabel('Total Area (um²)')
        fig.savefig(output_area_img)
    plt.close(fig)
    print(f"Saved {output_area_img}")

    # ==========================================
    # 2. Timing Slack Plot 
    # ==========================================
    fig, ax = plt.subplots()
    x_val, y_val = extract_valid_data(plot_freqs, avg_slacks)
    
    if x_val and y_val:
        ax.plot(x_val, y_val, marker='s', color='tab:red', linestyle='-', alpha=0.85, label='Timing Slack')
        ax.axhline(0, color='k', linestyle=':', linewidth=1.0)
        
        if max_freq_zero_slack is not None:
            ax.axvline(x=max_freq_zero_slack, color='k', linestyle='-.', linewidth=1.0, 
                        label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
                        
        ax.legend()

        # Inset zoom logic (Placed top-right since slack data drops down and right)
        add_inset_zoom(ax, x_val, y_val, [360, 375], 's', 'tab:red', max_freq_zero_slack, loc=[0.60, 0.55, 0.35, 0.35])

        ax.set_xlabel('Frequency (MHz)')
        ax.set_ylabel('Timing Slack (ps)')
        fig.savefig(output_slack_img)
    plt.close(fig)
    print(f"Saved {output_slack_img}")

    # ==========================================
    # 3. Total Power Plot
    # ==========================================
    fig, ax = plt.subplots()
    x_val, y_val = extract_valid_data(plot_freqs, avg_powers)
    
    if x_val and y_val:
        ax.plot(x_val, y_val, marker='^', color='tab:green', linestyle='-', alpha=0.85, label='Total Power')
                
        if max_freq_zero_slack is not None:
            ax.axvline(x=max_freq_zero_slack, color='k', linestyle='--', linewidth=1.0, 
                        label=f'Max Op. Freq ({max_freq_zero_slack} MHz)')
        
        ax.legend()
        
        # Inset zoom logic (Placed top-left assuming power follows Area trend)
        add_inset_zoom(ax, x_val, y_val, [360, 375], '^', 'tab:green', max_freq_zero_slack, loc=[0.1, 0.55, 0.35, 0.35])

        ax.set_xlabel('Frequency (MHz)')
        ax.set_ylabel('Total Power (W)')
        fig.savefig(output_power_img)
    plt.close(fig)
    print(f"Saved {output_power_img}")

if __name__ == "__main__":
    main()

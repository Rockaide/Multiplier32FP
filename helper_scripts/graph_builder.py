import csv
import os
import matplotlib.pyplot as plt
from collections import defaultdict

# --- Configuration ---
csv_file = "CSVs/TL_results.csv"
output_image = "CSVs/metrics_graphs.png"

def main():
    if not os.path.isfile(csv_file):
        print(f"Error: Could not find {csv_file}. Please ensure the extraction script has run.")
        return

    # Dictionaries to group values by frequency
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

        # Dynamically map column indices to handle layout changes
        try:
            idx_freq = headers.index("freq MHz (clk)")
            idx_area = headers.index("total um2")
            idx_slack = headers.index("timing slack ps")
            idx_power = headers.index("total (W)")
        except ValueError as e:
            print(f"Error mapping headers: {e}. Check if CSV header names match exactly.")
            return

        # Parse rows
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
                # Skip rows with malformed or incomplete numeric data
                continue

    # Aggregate and sort data
    sorted_freqs = sorted(list(set(list(areas.keys()) + list(slacks.keys()) + list(powers.keys()))))

    plot_freqs = []
    avg_areas = []
    avg_slacks = []
    avg_powers = []

    for f in sorted_freqs:
        plot_freqs.append(f)
        # Calculate averages for frequencies with multiple runtimes
        avg_areas.append(sum(areas[f])/len(areas[f]) if f in areas and areas[f] else None)
        avg_slacks.append(sum(slacks[f])/len(slacks[f]) if f in slacks and slacks[f] else None)
        avg_powers.append(sum(powers[f])/len(powers[f]) if f in powers and powers[f] else None)

    print("Generating plots...")

    # Create a figure with 3 subplots (Area, Slack, Power)
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(8, 12), sharex=True)

    # 1. Total Area Plot
    ax1.plot(plot_freqs, avg_areas, marker='o', color='blue', linestyle='-')
    ax1.set_ylabel('Total Area (um²)')
    ax1.set_title('Total Area vs. Frequency')
    ax1.grid(True, linestyle='--', alpha=0.7)

    # 2. Timing Slack Plot
    ax2.plot(plot_freqs, avg_slacks, marker='s', color='green', linestyle='-')
    ax2.set_ylabel('Timing Slack (ps)')
    ax2.set_title('Timing Slack vs. Frequency')
    ax2.axhline(0, color='red', linestyle='--', linewidth=1.5, label='Zero Slack Margin') # Add a zero line for slack
    ax2.legend()
    ax2.grid(True, linestyle='--', alpha=0.7)

    # 3. Total Power Plot
    ax3.plot(plot_freqs, avg_powers, marker='^', color='purple', linestyle='-')
    ax3.set_xlabel('Frequency (MHz)')
    ax3.set_ylabel('Total Power (W)')
    ax3.set_title('Total Power vs. Frequency')
    ax3.grid(True, linestyle='--', alpha=0.7)

    # Adjust layout and save
    plt.tight_layout()
    plt.savefig(output_image, dpi=300)
    print(f"Graph successfully saved to {output_image}")
    
    # Uncomment the line below to also open a window displaying the graphs
    # plt.show()

if __name__ == "__main__":
    main()
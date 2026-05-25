import os
import re
import csv

# --- Configuration ---
design_name = "multiplier32FP"
# Caminho absoluto pra não bugar
reports_base_dir = "../backend/synthesis/reports"
output_csv = "CSVs/TL_results.csv"

# Regexes
# Matches folder pattern
re_folder = re.compile(rf"^{design_name}_([a-zA-Z0-9\_]+)_(\d+)_(\d+)$")

re_area = re.compile(rf"^{design_name}\s+(?:\S+\s+)?(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)")
re_slack = re.compile(r"(?i)slack\s*[:=]+\s*([-\d\.]+)")
re_power = re.compile(r"(?i)Subtotal\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)")
re_probs = re.compile(r"([\w\[\]\_]+)\s*:\s+([\d\.e\-\+]+|N/A)")
re_startpoint = re.compile(r"Startpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")
re_endpoint = re.compile(r"Endpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")

def extract_metrics(folder_name):
    """Parses reports inside a dynamically discovered folder."""
    rpt_dir = os.path.join(reports_base_dir, folder_name)
    
    # Extract config parameters from folder name
    match_folder = re_folder.match(folder_name)
    if not match_folder:
        return None # Skips folders that don't match the standard naming convention
        
    lib = match_folder.group(1)
    freq = int(match_folder.group(2))
    runtime = match_folder.group(3)

    timing_file = os.path.join(rpt_dir, f"{design_name}_timing.rpt")
    
    # Skip extraction entirely if the timing report hasn't been generated
    if not os.path.isfile(timing_file):
        return None

    # Initialize defaults
    cell_count = "N/A"
    net_area = "N/A"
    total_area = "N/A"
    norm_area = "N/A"
    slack = "N/A"
    start_point = "N/A"
    end_point = "N/A"   
    leakage = "N/A"
    total_power = "N/A"
    dynamic_power = "N/A"
    
    sum_o7_tr = "N/A"
    sum_o7_prob = "N/A"
    a_i1_tr = "N/A"
    a_i1_prob = "N/A"

    # 1. AREA
    area_file = os.path.join(rpt_dir, f"{design_name}_area.rpt")
    if os.path.isfile(area_file):
        with open(area_file, 'r') as f:
            for line in f:
                match = re_area.search(line.strip())
                if match:
                    cell_count = match.group(1)
                    net_area = match.group(3)
                    total_area = match.group(4)
                    break

    # 2. NORMALIZED AREA
    norm_file = os.path.join(rpt_dir, f"{design_name}_normalized_area.rpt")
    if os.path.isfile(norm_file):
        with open(norm_file, 'r') as f:
            for line in f:
                match = re_area.search(line.strip())
                if match:
                    norm_area = match.group(4)
                    break

    # 3. TIMING (Slack, Startpoint, and Endpoint)
    with open(timing_file, 'r') as f:
        for line in f:
            if start_point == "N/A":
                match_s = re_startpoint.search(line)
                if match_s: start_point = match_s.group(1)
            
            if end_point == "N/A":
                match_e = re_endpoint.search(line)
                if match_e: end_point = match_e.group(1)

            match_slack = re_slack.search(line)
            if match_slack:
                slack = match_slack.group(1)
                break # Stop searching after finding the worst-case slack

    # 4. POWER
    power_file = os.path.join(rpt_dir, f"{design_name}_power.rpt")
    if os.path.isfile(power_file):
        with open(power_file, 'r') as f:
            for line in f:
                match = re_power.search(line.strip())
                if match:
                    leakage = match.group(1)
                    internal = float(match.group(2))
                    switching = float(match.group(3))
                    dynamic_power = f"{internal + switching:.5e}"
                    total_power = match.group(4)
                    break

    # 5. PROBABILITIES & TOGGLE RATES
    probabilities_file = os.path.join(rpt_dir, f"{design_name}_probabilities.rpt")
    if os.path.isfile(probabilities_file):
        with open(probabilities_file, 'r') as f:
            for line in f:
                match = re_probs.search(line.strip())
                if match:
                    key = match.group(1)
                    val = match.group(2)
                    
                    if "sum_o[7]_prob" in key: sum_o7_prob = val
                    elif "sum_o[7]_tr" in key: sum_o7_tr = val
                    elif "a_i[1]_prob" in key: a_i1_prob = val
                    elif "a_i[1]_tr" in key: a_i1_tr = val

    return [freq, lib, cell_count, net_area, total_area, norm_area, slack, start_point, end_point, runtime, 
            leakage, total_power, dynamic_power, sum_o7_tr, sum_o7_prob, a_i1_tr, a_i1_prob]

# --- Main Execution ---
def main():
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    
    if not os.path.isdir(reports_base_dir):
        print(f"Directory {reports_base_dir} does not exist.")
        return

    print(f"Scanning {reports_base_dir} for completed timing reports...")
    
    extracted_data = []
    for item in os.listdir(reports_base_dir):
        item_path = os.path.join(reports_base_dir, item)
        if os.path.isdir(item_path):
            row_data = extract_metrics(item)
            if row_data:
                extracted_data.append(row_data)
                
    # Sort data by frequency ascending for cleaner CSV output
    extracted_data.sort(key=lambda x: x[0])

    print(f"Extracted {len(extracted_data)} valid records. Writing to {output_csv}...")
    
    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        
        writer.writerow([
            "freq MHz (clk)", "library", "cell count", "net um2", "total um2", "gates total um2 equivalent", 
            "timing slack ps", "Start point", "End point", "Simulation Time (ns)", 
            "leakage (W)", "total (W)", "dynamic (W)", 
            "lp_computed_toggle_rate sum_o[7]", "lp_computed_probability sum_o[7]", 
            "lp_computed_toggle_rate a_i[1]", "lp_computed_probability a_i[1]"
        ])
        
        writer.writerows(extracted_data)
                
    print("Extraction complete.")

if __name__ == "__main__":
    main()
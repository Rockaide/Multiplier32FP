import os
import re
import csv

# --- Configuration ---
design_name = "multiplier32FP"
reports_base_dir = "../backend/layout/reports"
csv_dir = "CSVs"
output_static_csv = os.path.join(csv_dir, "layout_static_data.csv")
output_power_csv = os.path.join(csv_dir, "layout_power_data.csv")
output_final_csv = os.path.join(csv_dir, "layout_TL_results.csv")

# Only process folders matching these frequencies
target_freqs = [10, 368]

# --- Regexes for Innovus ---
re_folder = re.compile(rf"^{design_name}_([a-zA-Z0-9\_]+)_(\d+)_(\d+)$")

# Timing Regexes
re_slack = re.compile(r"(?i)slack\s*[:=]+\s*([-\d\.]+)")
re_startpoint = re.compile(r"Startpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")
re_endpoint = re.compile(r"Endpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")

# Power Regexes (Voltus format)
re_internal = re.compile(r"Total Internal Power:\s+([\d\.e\-\+]+)")
re_switching = re.compile(r"Total Switching Power:\s+([\d\.e\-\+]+)")
re_leakage = re.compile(r"Total Leakage Power:\s+([\d\.e\-\+]+)")
re_total_pwr = re.compile(r"^Total Power:\s+([\d\.e\-\+]+)")

def extract_static(folder_name):
    """Extracts timing from folders with runtime == 0 (Base Layout)"""
    rpt_dir = os.path.join(reports_base_dir, folder_name)
    match_folder = re_folder.match(folder_name)
    lib = match_folder.group(1)
    freq = int(match_folder.group(2))

    setup_slack, start_point, end_point, hold_slack = ["N/A"] * 4

    # Extract Setup Timing
    setup_file = os.path.join(rpt_dir, "setup_timing.rpt")
    if os.path.isfile(setup_file):
        with open(setup_file, 'r') as f:
            for line in f:
                if start_point == "N/A":
                    match_s = re_startpoint.search(line)
                    if match_s: start_point = match_s.group(1)
                
                if end_point == "N/A":
                    match_e = re_endpoint.search(line)
                    if match_e: end_point = match_e.group(1)

                match_slack = re_slack.search(line)
                if match_slack:
                    setup_slack = match_slack.group(1)
                    break 

    # Extract Hold Timing
    hold_file = os.path.join(rpt_dir, "hold_timing.rpt")
    if os.path.isfile(hold_file):
        with open(hold_file, 'r') as f:
            for line in f:
                match_slack = re_slack.search(line)
                if match_slack:
                    hold_slack = match_slack.group(1)
                    break

    return [freq, lib, setup_slack, hold_slack, start_point, end_point]

def extract_power(folder_name):
    """Extracts power from Voltus reports"""
    rpt_dir = os.path.join(reports_base_dir, folder_name)
    match_folder = re_folder.match(folder_name)
    lib = match_folder.group(1)
    freq = int(match_folder.group(2))
    runtime = match_folder.group(3)

    leakage, total_power, dynamic_power = ["N/A"] * 3
    internal_val, switching_val = 0.0, 0.0

    # Innovus power report naming convention from power.tcl
    power_file = os.path.join(rpt_dir, f"{design_name}_power_{runtime}ns.rpt")
    
    if os.path.isfile(power_file):
        with open(power_file, 'r') as f:
            for line in f:
                line = line.strip()
                
                m_int = re_internal.search(line)
                if m_int: internal_val = float(m_int.group(1))
                
                m_sw = re_switching.search(line)
                if m_sw: switching_val = float(m_sw.group(1))
                
                m_leak = re_leakage.search(line)
                if m_leak: leakage = m_leak.group(1)
                
                m_tot = re_total_pwr.search(line)
                if m_tot: 
                    total_power = m_tot.group(1)
                    break
                    
        # Calculate dynamic power (Internal + Switching)
        if total_power != "N/A":
            dynamic_power = f"{internal_val + switching_val:.5f}"

    return [freq, lib, runtime, leakage, total_power, dynamic_power]

def write_csv(file_path, headers, data):
    with open(file_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(headers)
        writer.writerows(data)

def main():
    os.makedirs(csv_dir, exist_ok=True)
    
    if not os.path.isdir(reports_base_dir):
        print(f"Directory {reports_base_dir} does not exist.")
        return

    print(f"Scanning directory for layout reports targeting frequencies: {target_freqs} MHz...")
    
    static_data = []
    power_data = []

    for item in os.listdir(reports_base_dir):
        item_path = os.path.join(reports_base_dir, item)
        if os.path.isdir(item_path):
            match_folder = re_folder.match(item)
            if not match_folder:
                continue
            
            # Filter by Target Frequencies
            freq = int(match_folder.group(2))
            if freq not in target_freqs:
                continue
            
            runtime = match_folder.group(3)
            if runtime == "0":
                static_data.append(extract_static(item))
            
            # Power is extracted for ALL runtimes (0, X, and 2X)
            power_data.append(extract_power(item))

    # Sort data
    static_data.sort(key=lambda x: (x[0], x[1]))
    power_data.sort(key=lambda x: (x[0], x[1], int(x[2])))

    # CSV Generation
    static_headers = ["freq MHz (clk)", "library", "Setup Slack (ns)", "Hold Slack (ns)", "Critical Startpoint", "Critical Endpoint"]
    write_csv(output_static_csv, static_headers, static_data)
    
    power_headers = ["freq MHz (clk)", "library", "Simulation Time (ns)", "Leakage Power (uW)", "Total Power (uW)", "Dynamic Power (uW)"]
    write_csv(output_power_csv, power_headers, power_data)

    # --- FULL OUTER JOIN MERGE ---
    static_dict = {(str(row[0]), row[1]): row[2:] for row in static_data}
    
    power_dict = {}
    for p_row in power_data:
        key = (str(p_row[0]), p_row[1])
        if key not in power_dict:
            power_dict[key] = []
        power_dict[key].append(p_row[2:])
        
    all_keys = set(static_dict.keys()).union(set(power_dict.keys()))
    
    merged_data = []
    for freq_str, lib_str in all_keys:
        s_data = static_dict.get((freq_str, lib_str), ["N/A"] * 4) 
        p_data_list = power_dict.get((freq_str, lib_str), [])
        
        if not p_data_list:
            merged_row = [freq_str, lib_str] + s_data + ["N/A"] * 4 
            merged_data.append(merged_row)
        else:
            for p_data in p_data_list:
                merged_row = [freq_str, lib_str] + s_data + p_data
                merged_data.append(merged_row)

    merged_data.sort(key=lambda x: (float(x[0]), x[1], float(x[6]) if x[6] != "N/A" else 0))

    merged_headers = static_headers[:2] + static_headers[2:] + power_headers[2:]
    write_csv(output_final_csv, merged_headers, merged_data)
    print(f"Extraction complete. Wrote layout data to {output_final_csv}")

if __name__ == "__main__":
    main()
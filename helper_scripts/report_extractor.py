import os
import re
import csv

# --- Configuration ---
design_name = "multiplier32FP"
reports_base_dir = "../backend/synthesis/reports"
csv_dir = "CSVs"
output_static_csv = os.path.join(csv_dir, "static_data.csv")
output_power_csv = os.path.join(csv_dir, "power_data.csv")
output_final_csv = os.path.join(csv_dir, "TL_results.csv")

# Regexes
re_folder = re.compile(rf"^{design_name}_([a-zA-Z0-9\_]+)_(\d+)_(\d+)$")
re_area = re.compile(rf"^{design_name}\s+(?:\S+\s+)?(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)")
re_slack = re.compile(r"(?i)slack\s*[:=]+\s*([-\d\.]+)")
re_power = re.compile(r"(?i)Subtotal\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)\s+([\d\.e\-\+]+)")
re_probs = re.compile(r"([\w\[\]\_]+)\s*:\s+([\d\.e\-\+]+|N/A)")
re_startpoint = re.compile(r"Startpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")
re_endpoint = re.compile(r"Endpoint:\s*(?:\([A-Za-z]\)\s*)?([\w\[\]\/\_\-]+)")

def extract_static(folder_name):
    """Extracts area and timing from folders with runtime == 0"""
    rpt_dir = os.path.join(reports_base_dir, folder_name)
    match_folder = re_folder.match(folder_name)
    lib = match_folder.group(1)
    freq = int(match_folder.group(2))

    cell_count, net_area, total_area, norm_area, slack, start_point, end_point = ["N/A"] * 7

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

    norm_file = os.path.join(rpt_dir, f"{design_name}_normalized_area.rpt")
    if os.path.isfile(norm_file):
        with open(norm_file, 'r') as f:
            for line in f:
                match = re_area.search(line.strip())
                if match:
                    norm_area = match.group(4)
                    break

    timing_file = os.path.join(rpt_dir, f"{design_name}_timing.rpt")
    if os.path.isfile(timing_file):
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
                    break

    return [freq, lib, cell_count, net_area, total_area, norm_area, slack, start_point, end_point]

def extract_power(folder_name):
    """Extracts power and toggle rates from folders with runtime > 0"""
    rpt_dir = os.path.join(reports_base_dir, folder_name)
    match_folder = re_folder.match(folder_name)
    lib = match_folder.group(1)
    freq = int(match_folder.group(2))
    runtime = match_folder.group(3)

    leakage, total_power, dynamic_power, sum_o7_tr, sum_o7_prob, a_i1_tr, a_i1_prob = ["N/A"] * 7

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

    return [freq, lib, runtime, leakage, total_power, dynamic_power, sum_o7_tr, sum_o7_prob, a_i1_tr, a_i1_prob]

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

    print("Scanning directory for timing reports...")
    
    static_data = []
    power_data = []

    for item in os.listdir(reports_base_dir):
        item_path = os.path.join(reports_base_dir, item)
        if os.path.isdir(item_path):
            match_folder = re_folder.match(item)
            if not match_folder:
                continue
            
            runtime = match_folder.group(3)
            if runtime == "0":
                static_data.append(extract_static(item))
            else:
                power_data.append(extract_power(item))

    static_data.sort(key=lambda x: (x[0], x[1]))
    power_data.sort(key=lambda x: (x[0], x[1], int(x[2])))

    static_headers = ["freq MHz (clk)", "library", "cell count", "net um2", "total um2", "gates total um2 equivalent", "timing slack ps", "Start point", "End point"]
    write_csv(output_static_csv, static_headers, static_data)
    
    power_headers = ["freq MHz (clk)", "library", "Simulation Time (ns)", "leakage (W)", "total (W)", "dynamic (W)", "lp_computed_toggle_rate sum_o[7]", "lp_computed_probability sum_o[7]", "lp_computed_toggle_rate a_i[1]", "lp_computed_probability a_i[1]"]
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
        s_data = static_dict.get((freq_str, lib_str), ["N/A"] * 7)
        p_data_list = power_dict.get((freq_str, lib_str), [])
        
        if not p_data_list:
            merged_row = [freq_str, lib_str] + s_data + ["N/A"] * 8
            merged_data.append(merged_row)
        else:
            for p_data in p_data_list:
                merged_row = [freq_str, lib_str] + s_data + p_data
                merged_data.append(merged_row)

    merged_data.sort(key=lambda x: (float(x[0]), x[1]))

    merged_headers = static_headers[:2] + static_headers[2:] + power_headers[2:]
    write_csv(output_final_csv, merged_headers, merged_data)
    print(f"Extraction complete. Wrote merged data to {output_final_csv}")

if __name__ == "__main__":
    main()
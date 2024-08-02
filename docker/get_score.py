#!/usr/bin/env python3
"""Extract the score from the scoring_file."""

import argparse
import json
import pandas as pd

def get_args():
    """Set up command-line interface and get arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--scoring_file", type=str, required=True)
    parser.add_argument("--results_file", type=str, required=True)
    return parser.parse_args()

def get_score(filename):
    """Get the score from the scoring file."""
    # Create a dataframe of the scoring file
    score_data = pd.read_excel(filename)

    # Record the score for display in the Synapse View
    final_score = score_data['Score'][0]

    return final_score

def update_results_file(results_file, score):
    """Update the results file with the new score."""
    try:
        with open(results_file, "r") as file:
            results_data = json.load(file)
    except (FileNotFoundError, json.JSONDecodeError):
        results_data = {}

    results_data["Score"] = score
    
    with open(results_file, "w") as file:
        json.dump(results_data, file, indent=4)

def main():
    """Main function."""
    args = get_args()
    score = get_score(args.scoring_file)
    
    # Update the results file with the score
    update_results_file(args.results_file, score)
    

if __name__ == "__main__":
    main()

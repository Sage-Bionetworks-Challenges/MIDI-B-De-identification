#!/usr/bin/env python3
"""Extract the score from the scoring_file."""

import argparse
import json
import pandas as pd

def get_args():
    """Set up command-line interface and get arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--scoring_file", type=str, required=True)
    # parser.add_argument("--results_file", type=str, required=True)
    parser.add_argument("-o", "--output", type=str)
    return parser.parse_args()

def get_score(filename):
    """Get the score from the scoring file."""
    # Create a dataframe of the scoring file
    score_data = pd.read_excel(filename)

    # Record the score for display in the Synapse View
    final_score = score_data['Score'][0]

    return final_score

def main():
    """Main function."""
    args = get_args()
    score = get_score(args.scoring_file)
    if args.output:
        with open(args.output, "w") as out:
            res = {
                "submission_status": "SCORED",
                "score": score  # Store the score value directly
            }
            out.write(json.dumps(res))
    else:
        print(score)

if __name__ == "__main__":
    main()

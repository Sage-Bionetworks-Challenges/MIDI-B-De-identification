#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
label: Get result files then upload to Synapse

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      # - entryname: setup.sh
      #   entry: |
          #!/bin/bash
          # pip install openpyxl
      - entryname: upload_results_to_synapse.py
        entry: |
          #!/usr/bin/env python
          import synapseclient
          import argparse
          import json
          import os

          parser = argparse.ArgumentParser()
          parser.add_argument("--discrepancy_file", required=True)
          parser.add_argument("--scoring_file", required=True)
          parser.add_argument("--score_value", required=True)
          parser.add_argument("--synapse_config", required=True)
          parser.add_argument("--parent_id", required=True)
          args = parser.parse_args()

          
          def print_score(data):
            """Print the value associated with the 'Score' key."""
            if 'Score' in data:
              print(f"{data['Score']}")
            else:
              print("Score key not found in the JSON file.")

          def read_json(file_path):
            """Read and return the contents of a JSON file."""
            with open(file_path, 'r') as file:
              data = json.load(file)
            return data
          
          data = read_json(args.score_value)
          
          # Begin template Synapse Upload script
          syn = synapseclient.Synapse(configPath=args.synapse_config)

          syn.login()

          results = {}

          discrepancy = synapseclient.File(args.discrepancy_file, parent=args.parent_id)
          discrepancy = syn.store(discrepancy)
          results['discrepancy'] = discrepancy.id

          scoring = synapseclient.File(args.scoring_file, parent=args.parent_id)
          scoring = syn.store(scoring)
          results['scoring'] = scoring.id

          # Add the score to synapse
          score = synapseclient.File(args.score_value, parent=args.parent_id)
          score = syn.store(scoring)
          results['Score'] = data

          with open('results.json', 'w') as out:
              json.dump(results, out)

inputs:
  - id: discrepancy_results
    type: File
  - id: scoring_results
    type: File
  - id: score_value
    type: File
  - id: parent_id
    type: string
  - id: synapse_config
    type: File

outputs:
  - id: results
    type: File
    outputBinding:
      glob: results.json

baseCommand: python3
arguments:
  - upload_results_to_synapse.py
  - valueFrom: --discrepancy_file
  - valueFrom: $(inputs.discrepancy_results.path)
  - valueFrom: --scoring_file
  - valueFrom: $(inputs.scoring_results.path)
  - valueFrom: --score_value
  - valueFrom: $(inputs.score_value.path)
  - valueFrom: --synapse_config
  - valueFrom: $(inputs.synapse_config.path)
  - valueFrom: --parent_id
  - valueFrom: $(inputs.parent_id)

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.7.2
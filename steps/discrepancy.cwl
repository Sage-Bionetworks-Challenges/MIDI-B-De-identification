#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Discrepancies

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validation_results.db  # Specify the target name
        entry: $(inputs.database_created.path)

inputs:
  compressed_file:
    type: File
    inputBinding:
      position: 1  # Ensures this input appears directly as the first argument
  database_created:
    type: File

outputs:
  scoring_results:
    type: File
    outputBinding:
      glob: 'results/**/scoring_report_series.xlsx'

  discrepancy_results:
    type: File
    outputBinding:
      glob: 'results/**/discrepancy_report_participant.csv'
  
  discrepancy_internal:
    type: File
    outputBinding:
      glob: 'results/**/discrepancy_report_internal.csv'

baseCommand: python
arguments:
  - -c
  - |
    import os
    import sys
    # Print the working directory and list files for debugging
    print("Working Directory: ", os.getcwd())
    print("Files in working directory: ", os.listdir(os.getcwd()))
    # Check if database file exists and is readable
    db_path = "database_created.db"
    if os.path.exists(db_path) and os.access(db_path, os.R_OK):
        print("Database file is accessible.")
    else:
        print("Database file is not accessible or does not exist.")
        sys.exit(1)
    # Execute the main script
    exec(open("/usr/local/bin/MIDI_validation_script/run_reports.py").read())
  - $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12

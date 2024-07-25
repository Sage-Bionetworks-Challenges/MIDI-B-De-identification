#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Discrepancies

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: validation_results.db
        entry: $(inputs.database_created.path)

inputs:
  compressed_file:
    type: File
    inputBinding:
      position: 1
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
    import glob
    # Print the working directory and list files for debugging
    print("Working Directory: ", os.getcwd())
    print("Files in working directory: ", os.listdir(os.getcwd()))
    # Check if database file exists and is readable
    db_files = glob.glob('**/validation_results.db', recursive=True)
    if db_files:
        db_path = db_files[0]
        print(f"Database file found: {db_path}")
        if os.access(db_path, os.R_OK):
            print("Database file is accessible.")
        else:
            print("Database file is not accessible.")
            sys.exit(1)
    else:
        print("Database file does not exist.")
        sys.exit(1)
    # Execute the main script
    exec(open("/usr/local/bin/MIDI_validation_script/run_reports.py").read())
  - $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12

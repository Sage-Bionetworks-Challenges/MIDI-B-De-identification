#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Discrepancies

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: 'results/MIDI_1_1_Testing/validation_results.db'
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
      glob: 'results/MIDI_1_1_Testing/scoring_report_series.xlsx'

  discrepancy_results:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/discrepancy_report_participant.csv'
  
  discrepancy_internal:
    type: File
    outputBinding:
      glob: 'results/MIDI_1_1_Testing/discrepancy_report_internal.csv'

baseCommand: python
arguments:
  - /usr/local/bin/MIDI_validation_script/run_reports.py
  - $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12

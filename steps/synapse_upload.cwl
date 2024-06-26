#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
label: Get result files then upload to Synapse

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: upload_results_to_synapse.py
    entry: |
      #!/usr/bin/env python
      import synapseclient
      import argparse
      import json
      import os
      import tarfile

      parser = argparse.ArgumentParser()
      parser.add_argument("--dciovdfy_file", required=True)
      parser.add_argument("--discrepancy_file", required=True)
      parser.add_argument("--scoring_file", required=True)
      parser.add_argument("-c", "--synapse_config", required=True)
      parser.add_argument("--parent_id", required=True)
      args = parser.parse_args()

      syn = synapseclient.Synapse(configPath=args.synapse_config)
      syn.login()

      results = {}

      dciovdfy = synapseclient.File(args.dciovdfy_file, parent=args.parent_id)
      dciovdfy = syn.store(dciovdfy)
      results['dciovdfy'] = dciovdfy.id

      discrepancy = synapseclient.File(args.discrepancy_file, parent=args.parent_id)
      discrepancy = syn.store(discrepancy)
      results['discrepancy'] = discrepancy.id

      scoring = synapseclient.File(args.scoring_file, parent=args.parent_id)
      scoring = syn.store(scoring)
      results['scoring'] = scoring.id
      with open('results.json', 'w') as out:
          json.dump(results, out)

inputs:
- id: dciovdfy_results
  type: File
- id: discrepancy_results
  type: File
- id: scoring_results
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
- id: dciovdfy_synid
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['dciovdfy'])
    loadContents: true

- id: discrepancy_synid
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['discrepancy'])
    loadContents: true

- id: scoring_synid
  type: string
  outputBinding:
    glob: results.json
    outputEval: $(JSON.parse(self[0].contents)['scoring'])
    loadContents: true


baseCommand: python3
arguments:
- valueFrom: upload_results_to_synapse.py
- prefix: --dciovdfy_file
  valueFrom: $(inputs.dciovdfy_results)
- prefix: --discrepancy_file
  valueFrom: $(inputs.discrepancy_results)
- prefix: --scoring_file
  valueFrom: $(inputs.scoring_results)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: --parent_id
  valueFrom: $(inputs.parent_id)

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.7.2
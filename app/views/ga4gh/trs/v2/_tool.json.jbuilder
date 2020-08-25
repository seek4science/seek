json.url workflow_path(workflow, format: :json)
json.id
json.organization
json.name workflow.title
json.versions do
  json.partial! 'tool_version', collection: workflow.versions, as: :workflow_version
end
#
# {
#     "url": "http://agora.broadinstitute.org/tools/123456",
#     "id": 123456,
#     "aliases": [
#         [
#             "630d31c3-381e-488d-b639-ce5d047a0142",
#             "dockstore.org:630d31c3-381e-488d-b639-ce5d047a0142",
#             "bio.tools:630d31c3-381e-488d-b639-ce5d047a0142"
#         ]
#     ],
#     "organization": "string",
#     "name": "string",
#     "toolclass": {
#         "id": "string",
#         "name": "string",
#         "description": "string"
#     },
#     "description": "string",
#     "meta_version": "string",
#     "has_checker": true,
#     "checker_url": "string",
#     "versions": [
#         {
#             "author": [
#                 "string"
#             ],
#             "name": "string",
#             "url": "http://agora.broadinstitute.org/tools/123456/versions/1",
#             "id": "v1",
#             "is_production": true,
#             "images": [
#                 {
#                     "registry_host": [
#                         "registry.hub.docker.com"
#                     ],
#                     "image_name": [
#                         "quay.io/seqware/seqware_full/1.1",
#                         "ubuntu:latest"
#                     ],
#                     "size": 0,
#                     "updated": "string",
#                     "checksum": [
#                         {
#                             "checksum": "77af4d6b9913e693e8d0b4b294fa62ade6054e6b2f1ffb617ac955dd63fb0182",
#                             "type": "sha256"
#                         }
#                     ],
#                     "image_type": "Docker"
#                 }
#             ],
#             "descriptor_type": [
#                 "CWL"
#             ],
#             "containerfile": true,
#             "meta_version": "string",
#             "verified": true,
#             "verified_source": [
#                 "string"
#             ],
#             "signed": true,
#             "included_apps": [
#                 "https://bio.tools/tool/mytum.de/SNAP2/1",
#                 "https://bio.tools/bioexcel_seqqc"
#             ]
#         }
#     ]
# }
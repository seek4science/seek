import sys
import argparse
import zipfile
from rocrate_validator import services, models

parser = argparse.ArgumentParser("validate-ro-crate")
parser.add_argument("filepath", help="The path to the RO-Crate file to validate")
args = parser.parse_args()

if not zipfile.is_zipfile(args.filepath):
    print("Uploaded file is not a zip file")
    sys.exit()

settings = services.ValidationSettings(
    rocrate_uri=args.filepath,
    profile_identifier='ro-crate-1.1',
    # Severity options are: REQUIRED, RECOMMENDED, and OPTIONAL
    requirement_severity=models.Severity.REQUIRED,
)

result = services.validate(settings)

if result.has_issues():
    for issue in result.get_issues():
        print(f"{issue.check.identifier}: {issue.message.replace(" "*8, u"\u00A0"*8)}")
from rocrate_validator import services, models

settings = services.ValidationSettings(
    rocrate_uri='/home/abby/workflow-1531-1.crate.zip',
    profile_identifier='ro-crate-1.1',
    # Severity options are: REQUIRED, RECOMMENDED, and OPTIONAL
    requirement_severity=models.Severity.REQUIRED,
)

result = services.validate(settings)

if result.has_issues():
    for issue in result.get_issues():
        print(f"{issue.check.identifier}: {issue.message.replace(" "*8, u"\u00A0"*8)}")
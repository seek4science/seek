# MIAPPE Batch Upload Test Coverage

## Overview
This document describes the comprehensive functional test coverage added for the MIAPPE Study batch upload feature in the StudiesController.

## Background
The MIAPPE (Minimum Information About a Plant Phenotyping Experiment) batch upload feature allows users to upload multiple studies at once using a zip file containing:
- An Excel template file with study metadata
- Associated data files

Prior to these tests, only unit tests existed for the extraction logic (`test/unit/studies/studies_extractor_test.rb`), but no functional controller tests validated the full user workflow.

## Test Coverage Added

### 1. Basic Access Tests
- **test 'should get batch_uploader page'** - Verifies the batch uploader form page loads successfully
- **test 'should require login for batch_uploader'** - Ensures authentication is required
- **test 'should require login for preview_content'** - Ensures authentication is required
- **test 'should require login for batch_create'** - Ensures authentication is required

### 2. Preview Content Tests
- **test 'should show error if no file provided to preview_content'** - Validates error handling when user forgets to select a file
- **test 'should preview content from valid zip file'** - Tests successful extraction and preview of MIAPPE zip file
- **test 'batch preview should extract license from file'** - Verifies license information is correctly extracted from the template
- **test 'batch preview should identify existing studies'** - Tests duplicate detection by comparing MIAPPE IDs with existing studies
- **test 'batch preview should extract study data files information'** - Verifies associated data files are properly extracted
- **test 'batch preview should extract correct study metadata'** - Validates that all MIAPPE metadata fields are correctly extracted
- **test 'batch preview should render preview form with study data'** - Ensures the preview page renders correctly with form fields populated

### 3. Batch Create Tests
- **test 'batch create should validate required MIAPPE fields'** - Tests validation of mandatory MIAPPE fields (id, title, start date, contact institution, etc.)
- **test 'batch create full workflow with valid data'** - End-to-end test of the complete upload workflow from zip file to study creation

## Test Fixtures Used
- **test/fixtures/files/study_batch.zip** - Contains sample MIAPPE template with 3 studies and associated data files

## MIAPPE Validation Coverage
The tests verify validation of these required MIAPPE fields:
- Study ID (id)
- Study Title (title)
- Study Start Date (study_start_date)
- Contact Institution (contact_institution)
- Geographic Location Country (geographic_location_country)
- Experimental Site Name (experimental_site_name)
- Description of the Experimental Design (description_of_the_experimental_design)
- Observation Unit Description (observation_unit_description)
- Description of Growth Facility (description_of_growth_facility)

## Controller Actions Tested

### batch_uploader (GET)
- Renders the upload form
- Requires authentication

### preview_content (POST)
- Accepts zip file upload
- Extracts studies from MIAPPE template
- Extracts associated data files
- Identifies existing studies by MIAPPE ID
- Extracts license information
- Renders preview form with editable study data

### batch_create (POST)
- Validates all study data
- Creates Study records with ExtendedMetadata
- Creates Assay and DataFile records for associated files
- Handles validation errors gracefully
- Redirects to studies index on success

## Edge Cases Covered
1. **Missing file upload** - User submits form without selecting a file
2. **Missing required fields** - Study data lacks mandatory MIAPPE fields
3. **Duplicate studies** - System detects and flags existing studies with same MIAPPE ID
4. **Authentication** - Unauthenticated users cannot access any batch actions

## Test Approach
Tests follow the existing pattern in studies_controller_test.rb:
- Use FactoryBot to create test data
- Use fixture_file_upload for file uploads
- Use assert_select for view verification
- Use assert_response for HTTP response checks
- Use assert_difference for database changes
- Follow naming conventions (test 'description')

## Future Enhancements
These tests establish a solid foundation. Future tests could cover:
1. Lock file handling (mentioned as a known issue)
2. Better error messaging for 500 errors (mentioned as a known issue)
3. Invalid zip file formats
4. Corrupted template files
5. Missing data files referenced in template
6. Concurrent uploads by multiple users
7. Large file handling
8. Permission checks (project membership)

## Running the Tests
```bash
# Run all functional tests
rails test test/functional/studies_controller_test.rb

# Run specific MIAPPE batch upload tests
rails test test/functional/studies_controller_test.rb -n "/batch/"

# Run a single test
rails test test/functional/studies_controller_test.rb -n "test_should_get_batch_uploader_page"
```

## Dependencies
- MIAPPE Extended Metadata Type factory: `:study_extended_metadata_type_for_MIAPPE`
- Test fixture: `test/fixtures/files/study_batch.zip`
- StudyBatchUpload model with extraction methods
- Studies controller with batch upload actions

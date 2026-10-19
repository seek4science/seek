# Example Data Seeding

This directory contains classes for seeding example data into the SEEK database.

## Structure

The example data seeding is organized into modular classes located in `lib/seek/example_data/`:

- **`Seek::ExampleDataSeeder`** - Main orchestrator class that coordinates all seeding
- **`Seek::ExampleData::ProjectsSeeder`** - Seeds programmes, projects, institutions, workgroups, strains, and organisms
- **`Seek::ExampleData::UsersSeeder`** - Seeds users, people, and updates project/institution details
- **`Seek::ExampleData::IsaStructureSeeder`** - Seeds ISA structure (investigations, studies, assays, observation units)
- **`Seek::ExampleData::SamplesSeeder`** - Seeds sample types and sample instances
- **`Seek::ExampleData::DataFilesAndModelsSeeder`** - Seeds data files, models, and SOPs
- **`Seek::ExampleData::PublicationsSeeder`** - Seeds publications, presentations, and events
- **`Seek::ExampleData::ConfigurationSeeder`** - Seeds configuration settings and activity logs

## Usage

The example data can be seeded using the standard Rails seeding mechanism:

```bash
bundle exec rake db:seed:example_data
```

Or programmatically:

```ruby
seeder = Seek::ExampleDataSeeder.new
seeder.seed_all
```

## Testing

Unit tests for the seeder classes are located in `test/unit/lib/seek/example_data/`:

```bash
bundle exec rails test test/unit/lib/seek/example_data/
```

## Adding New Example Data

To add new example data:

1. Identify which seeder class is most appropriate (or create a new one if needed)
2. Add the seeding logic to that class's `seed` method
3. Ensure the seeder returns any important objects in its result hash
4. Update `Seek::ExampleDataSeeder` to call your new seeder and store results if needed
5. Add corresponding tests to verify the seeding works correctly

## Benefits of This Structure

- **Maintainability**: Each seeder class has a single responsibility
- **Testability**: Individual seeders can be tested in isolation
- **Extensibility**: Easy to add new types of example data
- **Clarity**: Dependencies between data types are explicit in the main orchestrator
- **Reusability**: Individual seeders can be used independently if needed

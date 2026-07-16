# frozen_string_literal: true

# Adds Solid Queue's tables to the primary database (shared, not a separate queue database).
# Table definitions mirror solid_queue 1.4.0's bundled db/queue_schema.rb, translated into a
# regular migration.
class CreateSolidQueueTables < ActiveRecord::Migration[7.1]
  def change
    create_table :solid_queue_jobs do |t|
      t.string :queue_name, null: false
      t.string :class_name, null: false
      t.text :arguments
      t.integer :priority, default: 0, null: false
      t.string :active_job_id
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.string :concurrency_key
      t.timestamps

      t.index :active_job_id
      t.index :class_name
      t.index :finished_at
      t.index %i[queue_name finished_at], name: 'index_solid_queue_jobs_for_filtering'
      t.index %i[scheduled_at finished_at], name: 'index_solid_queue_jobs_for_alerting'
    end

    create_table :solid_queue_scheduled_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :created_at, null: false

      t.index %i[scheduled_at priority job_id], name: 'index_solid_queue_dispatch_all'
    end

    create_table :solid_queue_ready_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :created_at, null: false

      t.index %i[priority job_id], name: 'index_solid_queue_poll_all'
      t.index %i[queue_name priority job_id], name: 'index_solid_queue_poll_by_queue'
    end

    create_table :solid_queue_claimed_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.bigint :process_id
      t.datetime :created_at, null: false

      t.index %i[process_id job_id]
    end

    create_table :solid_queue_blocked_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :queue_name, null: false
      t.integer :priority, default: 0, null: false
      t.string :concurrency_key, null: false
      t.datetime :expires_at, null: false
      t.datetime :created_at, null: false

      t.index %i[expires_at concurrency_key], name: 'index_solid_queue_blocked_executions_for_maintenance'
      t.index %i[concurrency_key priority job_id], name: 'index_solid_queue_blocked_executions_for_release'
    end

    create_table :solid_queue_failed_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.text :error
      t.datetime :created_at, null: false
    end

    create_table :solid_queue_pauses do |t|
      t.string :queue_name, null: false
      t.datetime :created_at, null: false

      t.index :queue_name, unique: true
    end

    create_table :solid_queue_processes do |t|
      t.string :kind, null: false
      t.datetime :last_heartbeat_at, null: false
      t.bigint :supervisor_id
      t.integer :pid, null: false
      t.string :hostname
      t.text :metadata
      t.datetime :created_at, null: false
      t.string :name, null: false

      t.index :last_heartbeat_at
      t.index %i[name supervisor_id], unique: true
      t.index :supervisor_id
    end

    create_table :solid_queue_semaphores do |t|
      t.string :key, null: false
      t.integer :value, default: 1, null: false
      t.datetime :expires_at, null: false
      t.timestamps

      t.index :key, unique: true
      t.index %i[key value]
      t.index :expires_at
    end

    create_table :solid_queue_recurring_tasks do |t|
      t.string :key, null: false
      t.string :schedule, null: false
      t.string :command, limit: 2048
      t.string :class_name
      t.text :arguments
      t.string :queue_name
      t.integer :priority, default: 0
      t.boolean :static, default: true, null: false
      t.text :description
      t.timestamps

      t.index :key, unique: true
      t.index :static
    end

    create_table :solid_queue_recurring_executions do |t|
      t.references :job, null: false, index: { unique: true }
      t.string :task_key, null: false
      t.datetime :run_at, null: false
      t.datetime :created_at, null: false

      t.index %i[task_key run_at], unique: true
    end

    add_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_failed_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_ready_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
    add_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs, column: :job_id, on_delete: :cascade
  end
end

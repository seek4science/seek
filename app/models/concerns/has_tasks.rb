module HasTasks
  extend ActiveSupport::Concern

  included do
    has_many :tasks, as: :resource, dependent: :destroy
  end

  class_methods do
    def has_task(task_key)
      task_method = "#{task_key}_task"

      has_one :"#{task_method}", class_name: 'Task', as: :resource, dependent: :destroy

      define_method(task_method) do
        super() || send("build_#{task_method}")
      end
    end
  end
end

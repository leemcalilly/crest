# crest is a read-only site. Its whole database is one import from the open
# files in db/source, so seeding and importing are the same act.
if Match.none?
  Rails.application.load_tasks unless Rake::Task.task_defined?("crest:import")
  Rake::Task["crest:import"].invoke
end

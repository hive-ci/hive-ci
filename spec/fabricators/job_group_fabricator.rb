Fabricator(:job_group) do
  batch        { Fabricate(:batch) }
  hive_queue { Fabricate(:hive_queue) }
  name         { sequence(:job_group) { |i| "Job Group #{i}" } }
end

Fabricator(:job_group_with_job, from: :job_group) do
  after_create do |job_group, _transients|
    job_group.jobs << Fabricate(:job, job_group: job_group)
  end
end

Fabricator(:batch) do
  project { Fabricate(:project) }
  name { "Fabricated Batch #{Fabricate.sequence(:fabricated_job)}" }
  version { 123 }
  execution_variables { { 'tests_per_job' => '10', 'retries' => 1, 'job_timeout' => 300 } }
end

Fabricator(:batch_with_job, from: :batch) do
  after_create do |batch, _transients|
    batch.job_groups << Fabricate(:job_group_with_job, batch: batch)
  end
end

%i[running queued errored].each do |state|
  Fabricator("#{state}_batch".to_sym, from: :batch_with_job) do
    after_create do |batch, _transients|
      batch.jobs.each do |job|
        job.update(state: state)
      end
    end
  end
end

%i[passed failed].each do |result|
  Fabricator("#{result}_batch".to_sym, from: :batch_with_job) do
    after_create do |batch, _transients|
      batch.jobs.each do |job|
        job.update(state: :complete, result: result)
      end
    end
  end
end

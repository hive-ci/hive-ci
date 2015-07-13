class Job < ActiveRecord::Base
  include JobValidations
  include JobStateMachine
  include JobChart
  include JobArtifacts
  include JobAssociations
  include Cachethod
  include JobResult
  include JobDevice

  class << self
    def state_counts
      @counts = self.where( 'id IN (?)', Job.last(1000) ).group(:state, :result).count.reduce({}) do |h, i|
        if i.first.first == 'complete'
          h[i.first.second] = i.second
        elsif ['preparing', 'running', 'analyzing'].include? i.first.first
          h['running'] = h['running'].to_i + i.second
        else
          h[i.first.first] = i.second
        end
        h
      end
      
      @counts.default = 0
      @counts
    end
  end

  cache_class_method :state_counts, expires_in: 2.minutes

  serialize :execution_variables, JSON
  serialize :reservation_details, JSON

  self.per_page = 20

  scope :active, -> { joins("LEFT JOIN jobs AS replacement_jobs ON jobs.id = replacement_jobs.original_job_id").where(replacement_jobs: { original_job_id: nil }) }
  scope :completed, -> { where("state in ('complete', 'errored')") }
  scope :running, -> { where(state: ["preparing", "running", "analyzing"] ) }
  delegate :queue_name, to: :job_group

  def retry
    if can_retry?
      total_test_count = self.passed_count.to_i + self.failed_count.to_i + self.errored_count.to_i
      # If there is a zero test count, set it to nil, i.e. unknown
      total_test_count = nil if total_test_count == 0

      self.replacement = Job.new(
          job_name:            self.job_name,
          queued_count:        total_test_count,
          retry_count:         self.retry_count + 1,
          job_group:           self.job_group,
          original_job:        self,
          execution_variables: self.execution_variables
      )
    end
  end
  
  def status
    self.result || self.state
  end

  def retried?
    replacement.present?
  end

  def all_tests_passing?
    self.failed_count.to_i == 0 && self.errored_count.to_i == 0 && self.passed_count > 0
  end

  def can_retry?
    ['failed', 'errored'].include?(self.status) unless retried?
  end
  
  def can_cancel?
    ['queued', 'reserved'].include?(self.status)
  end
  

  # TODO replace this with a more elegant and non tests or test_rail specific implementation e.g: something that can deal with cuke tags, etc, also
  # will leave until further requirements and design is understood
  def tests
    execution_variables['tests']
  end

  def reservation_valid?
    (Time.now - self.reserved_at) < Chamber.env.job_reservation_timeout if reserved?
  end
  
  private

  # TODO replace this with a more elegant and non tests or test_rail specific implementation e.g: something that can deal with cuke tags, etc, also
  # will leave until further requirements and design is understood
  def run_id
    job_group.execution_variables['run_id']
  end
end

# the controll server and how to reach it
control identifier: "hop_hop_SOMETESTING82348",
        wait_spinup: 10

root File.expand_path('../environment', __FILE__)

driver :rails_prefork do

  setup do |config|
    # require 'pjpp/forking'
    #::Pjpp::Forking.setup_fork # deconnect and reconnect persistent connections
    # $: << root.join('event_consumers') # add consumers to the path so we can require them
  end

  before_fork # { ::Pjpp::Forking.before_fork }
  after_fork # { ::Pjpp::Forking.after_fork }
  # in defaults
  consumer_logger do |consumer| Rails.logger end
  stdout_filename { root.join('log', 'hop_hop_prefork_stdout.log') }
  logger { Rails.logger }
end

consumer 'Career::JobIndexingConsumer', role: :indexing
consumer 'Career::RecruiterIndexingConsumer', role: :indexing
consumer 'Recruiting::AccountNoteIndexingConsumer', role: :indexing
consumer 'Recruiting::CandidateBookmarkIndexingConsumer', role: :indexing
consumer 'Recruiting::CandidateIndexingConsumer', role: :indexing
consumer 'Recruiting::ContactIndexingConsumer', role: :indexing
consumer 'Recruiting::JobViewIndexingConsumer', role: :indexing

consumer 'Recruiting::CareerAdapterConsumer', role: :background
consumer 'Ja::AssemblyLineConsumer', role: :background

# this gives the system a hint what to start on witch node
host 'dietrich', role: :indexing
host 'jakob', role: :background

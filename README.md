# HopHop

HopHop is our (experteer's) small abstraction layer on top of Bunny to access our message queue.

## Development

The code is at https://github.com/experteer/hop_hop

## Installation


Add this line to your application's Gemfile:

    gem 'hop_hop'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hop_hop

## Usage
In Testing:
    HopHop::Event.sender = HopHop::TestSender.new()
    HopHop::Event.receiver = HopHop::TestReceiver.new()

in non testing environments:
    HopHop::Event.sender= HopHop::BunnySender.new(:host => x, :port => y)
    HopHop::Event.receiver = HopHop::BunnyReceiver.new(:host => x, :port => y)

See http://trac.admin.experteer.com/trac/wiki/dev/Messagebus in our wiki.
### The configuration ###
In Rails (there is currently just a preforking driver for Rails) create a file config/hop_hop.rb:
    HopHop.config do
      driver :rails_prefork,
             :rails_root => File.expand_path('../environment', __FILE__),
             :setup => proc { 'do something once when the environment is up' },
             :start_consumer => proc { 'do something before the consumer is run' },
             :stop_consumer => proc { 'do something after the consumer has stopped}
      stdout '/tmp/out' # or stdout proc { Rails.logger }
      logger proc {Rails.logger}
      consumer_logger { |consumer| Rails.logger }

      consumer 'MyMassmailerConsumerClass', :role => :mass_mailer

      host 'a hostname', :indexing #you can assign roles to hosts here, then hop_hop will look
                                   #here and the hostname to figure out what to start
    end

### The consumer ###

    class TestConsumer < HopHop::Consumer
      queue "pjpp_testconsumer" # the queue name, don't set this if you want to have excluse,temporary queues
      bind "career.test.#","career.othertest.*"  # bind to event(s)
      bind "career.testing"                      # multiple lines are possible

      def on_init                                # this is called after initialize
        logger.debug "debug"
        logger.info "info"
        @error_count=0                           
      end
  
      def on_bind                                # this is called after the binding to the queue but before consume
        loger.info("I'm bound yeah!")
      end
  
      def on_error(err)                          # this is called when consume raises an exception, retu
         @error_count +=1                        # it should return one of :ignore, :exit (default), :requeue
         if @error_count == 5                    # :requeue is dangerous so the loop will wait some seconds before it 
           :exit #the default                    # continues
         else
           :ignore
         end
      end

      def consume(consume_event, info)           #the meat of the consumer
        logger.info "consuming: #{consume_event.data.inspect} "
        exit_loop if consume_event.data["exit"]                        #you can exit the loop
        raise "I was forced to raise" if consume_event.data["error"]   #or raise errors (your on_error handler will be called back
      end
    end

### running consumers ###

The hop_hop binary can fire up/restart/check/stop your consumers.

TBD: the config file (see pjpp config/hop_hop_consumers.rb for an example)


Examples:
To stop and start your consumers e.g. after a deployment you should run:
  bundle exec hop_hop restart -l log/hop_hop_consumers -c config/hop_hop_consumers.rb
Stdout/stderr will got to the log file. You can also use 'start' instead of 'restart', they are aliases.

To stop all consumers and bring down the fork server just run:
  bundle exec hop_hop stop -l log/hop_hop_consumers -c config/hop_hop_consumers.rb
This will TERM the consumers and will also bring down the fork server.

To just check if everything is up just run:
  bundle exec hop_hop check -l log/hop_hop_consumers -c config/hop_hop_consumers.rb
The exit code is 0 if all is up and there aren't too many consumers running 1 else.

To check and fix run the following:
  bundle exec hop_hop adjust -l log/hop_hop_consumers -c config/hop_hop_consumers.rb
This will not reload the (Rails) environment but will just try to get the consumer up.
Exit code is the same as wicth check.


## Contributing

1. Checkout the code http://gitlab.experteer.com/experteer/hop_hop
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

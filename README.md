# HopHop

HopHop is our (experteer's) small abstraction layer on top of Bunny to access our message queue.

## Development

The code is at http://gitlab.experteer.com/experteer/hop_hop/tree/master

## Installation


Add this line to your application's Gemfile:

    gem 'hop_hop'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hop_hop

## Usage

Set HopHop::Event.sender either to HopHop::BunnySender.new(:host => x, :port => y) or to HopHop::TestSender.new() in case of testing.
Set HopHop::Event.receiver either to HopHop::BunnyReceiver.new(:host => x, :port => y) or to HopHop::TestReceiver.new() in case of testing.


See http://trac.admin.experteer.com/trac/wiki/dev/Messagebus in our wiki.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/hop_hop/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

require "hop_hop/helper"
require "hop_hop/version"
require "hop_hop/bunny_sender"
require "hop_hop/bunny_receiver"
require "hop_hop/queue_connection"
require "hop_hop/queue_info"
require "hop_hop/consume_event"
require "hop_hop/event"
require "hop_hop/consumer"

# for start/stop/cronjobs
require 'hop_hop/consumer_config'
require 'hop_hop/consumers_config'
require 'hop_hop/consumer_server'
require 'hop_hop/run_state'
require 'hop_hop/consumer_bin'
require 'hop_hop/consumer_server'
require 'hop_hop/consumer_ctrl'

# stdlib
require 'drb/drb'
require 'optparse'
require 'pathname'
require 'sys/proctable'

require "bunny"

module HopHop
end
